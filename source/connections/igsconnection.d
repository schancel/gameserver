module connections.igsconnection;

import std.stdio;
import core.time;
import std.conv;
import std.string;
import std.traits;
import std.exception;

import vibe.core.core;
import vibe.core.driver;
import vibe.http.server;
import vibe.stream.ssl;
import vibe.core.concurrency;
import vibe.core.log;
import vibe.stream.operations;

import connections.core;
import channels;
import user.userinfo;
import util.stringutils;
import messages;

const prompt = "1 5";
/****************************************************************************************

 *****************************************************************************************/
class IGSConnection : ConnectionBase
{ 
    private TCPConnection socket;
    private IGSCommahdHandler ch;
    GoChannel currentGame;

    this(TCPConnection _conn)
    {
        super();
        socket = _conn;
        ch = new  IGSCommahdHandler(this);
        curThread = 1; //TODO: Fix this
    }

    void readLoop()
    {
        logDebug("%d: IGS ReadTask Started", curThread);
        try
        { 
            while(socket.connected && active)
            {
                
                send(prompt);
                auto msg = cast(string)socket.readLine();
                try {
                    ch.handleInput( msg );
                } catch( Exception e)
                {
                    send("5 " ~ e.msg);
                }
            }
        } catch( Exception e ) {
            active = false;
        }
    }
    
    private void writeLoop()
    {
        logDebug("%d: IGS WriteTask Started", curThread);
        try {
            while(active)
            {
                receive( (shared Message m_) {
                    auto m = cast(Message)m_; //Remove shared
                    if(m.supportsIGS)
                    {
                        logDebug("%d: Sending Message", curThread); 
                        m.writeIGS(socket);
                        socket.write("\r\n");
                    }
                }, //Send raw messages to the client.
                (string m) {
                    socket.write(m);
                    socket.write("\r\t\n");
                });
            }
        }
        catch( InterruptException e)
        {
            //Shutting down
        }
    }
    
    void spawn()
    {
        //Print MOTD
        socket.write(import("motd.txt"));
        socket.write("\r\n");
        
        //Authenticate user:
        socket.write("Login: ");
        string username = cast(string)socket.readLine();
        socket.write("Password: ");
        string password = cast(string)socket.readLine();

        //Spawn readers and writers
        writeTask = runTask(&writeLoop);
        readTask = runTask(&readLoop);

        //Process info -- needs to be done after spawning reader and writer.
        auto msg = new AuthMessage(username, password);
        msg.handleMessage(this);

        new JoinMessage("Earth").handleMessage(this);

        readTask.join();
        active = false;
        writeTask.interrupt();
    }

    void send( string m )
    {
        writeTask.send(m);
    }
}

class IGSCommahdHandler
{
    private IGSConnection ci;
    
    this(IGSConnection _ci)
    {
        ci = _ci;
    }
    
    void handleInput(string msg)
    {
        string cmd = msg.readArg();
        switch( cmd.toUpper() )
        {
            /*
             Abuse compile-time-reflections to delegate out 
             */
            foreach(memberFunc; __traits(allMembers, typeof(this)) )
            {
                static if ( memberFunc.startsWith("cmd") )
                {
                    case memberFunc[3..$].toUpper():
                    alias ParameterTypeTuple!(MemberFunctionsTuple!(typeof(this), memberFunc)) ArgTypes;
                    ArgTypes args;
                    foreach(i, arg; ArgTypes)
                    {
                        if(i+1 == ArgTypes.length)
                            args[i] = to!arg(msg.readAll());
                        else
                            args[i] = to!arg(msg.readArg());
                    }
                    MemberFunctionsTuple!(typeof(this), memberFunc)[0](args);
                    goto end;
                }
            }
            default:
                enforce(ProcessContextualCommand(cmd, msg), cmd~": Unknown command.");
                break;
        }
    end:
        return;
    }

    bool ProcessContextualCommand(string cmd, string msg)
    {
        //TODO: IGS moves are simply played in the format "A1", etc.  Need to process them here.
        //Move format does not include the letter "i".  What a pain in the ass.
        return false;
    }

    void cmdSay(string message)
    {
        //TODO: implement talking in games.
    }

    void cmdKibitz(string message)
    {
        //TODO: implement talking in games.
    }

    void cmdFree()
    {
        //TODO: implement switching to free game.
    }

    void cmdHandicap(int stones)
    {
        //TODO: implement setting handicap.
    }

    void cmdMatch(string opponent, string myColor /+B/W+/, int size, int time, int byoyomitime)
    {
        //TODO: Implement match command.
    }
    
    void cmdJoin(string channel) {
        new JoinMessage(channel).handleMessage(ci);
    }
    
    void cmdPart(string channel)
    {
        new PartMessage(channel).handleMessage(ci);
    }

    void cmdNick(string newName, string password)
    {
        new AuthMessage(newName, password).handleMessage(ci);
    }

    void cmdShout(string message)
    {
        new ChatMessage("Earth", message).handleMessage(ci);
    }

    void cmdTell(string who, string message)
    {
        new PrivateMessage(who, message).handleMessage(ci);
    }

    void cmdWho(string channel)
    {
        new WhoMessage(channel == "" ? "Earth" : channel).handleMessage(ci);
    }

    void cmdGames()
    {
        ci.send("7 [##]  white name [ rk ]      black name [ rk ] (Move size H Komi BY FR) (###)");
    }

    //Are you there?
    void cmdAYT()
    {
        ci.send("9 yes");
    }

    void cmdToggle(string variable, string status)
    {
        bool val = ci.prefs.get(variable, false);
        switch(status)
        {
            case "on":
                val = true;
                break;
            case "off":
                val = false;
                break;
            default:
                val = !val;
        }
        ci.prefs[variable] = val;

        ci.send("9 Set "~variable ~" to be " ~ to!string(val) ~".");
    }
}
