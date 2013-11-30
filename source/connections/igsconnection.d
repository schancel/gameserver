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
import util.igs;

import connections.igscodes;

/****************************************************************************************

 *****************************************************************************************/
class IGSConnection : ConnectionBase
{ 
    private TCPConnection socket;
    private IGSCommandHandler ch;
    GoChannel currentGame;
    IGS_States state = IGS_States.WAITING;

    this(TCPConnection _conn)
    {
        super();
        socket = _conn;
        ch = new IGSCommandHandler(this);
    }

    void readLoop()
    {
        logDebug("%d: IGS ReadTask Started", curThread);
        try
        { 
            while(socket.connected && active)
            {
                
                prompt(state);
                auto msg = cast(string)socket.readLine();
                try {
                    ch.handleInput( msg );
                } catch( Exception e)
                {
                    send(IGS_CODES.ERROR, e.msg);
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
                },
                //Send raw messages to the client.
                (IGS_CODES code, string m) {
                    foreach( line; m.splitLines())
                    {
                        socket.write((cast(int)code).to!string);
                        socket.write(" ");
                        socket.write(line);
                        socket.write("\r\n");
                    }
                },
                (IGS_States state) {
                    socket.write((cast(int)IGS_CODES.PROMPT).to!string);
                    socket.write(" ");
                    socket.write((cast(int)state).to!string);
                    socket.write("\r\n");
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

        if( writeTask.running() )
            writeTask.interrupt();
       
        socket.close();
    }

    void send( IGS_CODES code, string m )
    {
        writeTask.send(code, m);
    }

    void prompt( IGS_States code )
    {
        writeTask.send(code);
    }
}

class IGSCommandHandler
{
    struct CmdAlias { string otherName; }

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
            /+static+/ foreach(memberFunc; __traits(allMembers, typeof(this)) )
            {
                static if ( memberFunc.startsWith("cmd") )
                {
                    alias memberIdentifer = MemberFunctionsTuple!(typeof(this), memberFunc)[0];

                    //Support command aliases.
                    /+static+/ foreach(a; __traits(getAttributes, memberIdentifer)) {
                        static if( is( typeof(a) == CmdAlias ))
                        {
                            case a.otherName.toUpper():
                        }
                    }

                    case memberFunc[3..$].toUpper():

                    alias ParameterTypeTuple!(memberIdentifer) ArgTypes;
                    ArgTypes args;
                    foreach(i, arg; ArgTypes)
                    {
                        string argInput;

                        if(i+1 == ArgTypes.length)
                            argInput = msg.readAll();
                        else
                            argInput = msg.readArg();

                        if(argInput.length) //Don't try to convert if argument is not specified.
                            args[i] = to!arg(argInput);
                    }
                    memberIdentifer(args);
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
        if( cmd.length > 1 && cmd.length <= 3 && ci.currentGame)
        {
            string sgfPos = cmd.toLower().igsToSgf();
            new PlayMoveMessage(ci.currentGame.name, sgfPos).handleMessage(ci);
            return true;
        } else {
            return false;
        }
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

    @CmdAlias("exit") @CmdAlias("logout")
    void cmdQuit()
    {
        ci.quit();
    }

    void cmdPrintGame()
    {
        ci.send(IGS_CODES.FILE, ci.currentGame.rawBoard().toString());
        ci.send(IGS_CODES.FILE, ci.currentGame.sgfData.toSgf());
    }

    void cmdMatch(string opponent, string myColor /+B/W+/, int size, int time, int byoyomitime)
    {
        import goban.colors;
        //TODO: Implement match command.
        ci.currentGame = new GoChannel(ci);
        ci.currentGame.readyPlayer(ci);
        ci.currentGame.startGame();

        ci.state = IGS_States.PLAYING_GO;
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
    
    @CmdAlias("w")
    void cmdWho(string channel)
    {
        new WhoMessage(channel == "" ? "Earth" : channel).handleMessage(ci);
    }

    void cmdGames()
    {
        ci.send(IGS_CODES.GAMES, "[##]  white name [ rk ]      black name [ rk ] (Move size H Komi BY FR) (###)");
    }

    //Are you there?
    void cmdAYT()
    {
        ci.send(IGS_CODES.INFO, "yes");
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

        ci.send(IGS_CODES.INFO, "Set "~variable ~" to be " ~ to!string(val) ~".");
    }
}
