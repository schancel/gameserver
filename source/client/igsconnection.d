module client.igsconnection;

import std.container;
import std.stdio;
import core.time;
import std.conv;
import std.array : join;
import std.string;
import std.traits;
import std.exception;
import std.file;

import vibe.core.core;
import vibe.core.driver;
import vibe.http.server;
import vibe.stream.ssl;
import vibe.core.concurrency;
import vibe.core.log;
import vibe.stream.operations;

import client.connection;
import gameserver.channels;
import user.userinfo;
import util.util;
import client.messages;

const prompt = "1 5";
/****************************************************************************************

 *****************************************************************************************/
class IGSConnection : ConnectionInfo
{ 
    private TCPConnection socket;
    private IGSMessageHandler mh;

    this(TCPConnection _conn)
    {
        super();
        socket = _conn;
        mh = new  IGSMessageHandler(this);
        curThread = 1; //TODO: Fix this

        socket.write(import("motd.txt"));
        socket.write("\r\n");
        socket.write("Login: ");
        string username = cast(string)socket.readLine();
        socket.write("Password: ");
        string password = cast(string)socket.readLine();

        user = new UserInfo(username, password);
    }

    void readLoop()
    {
        debug writefln("%d: IGS ReadTask Started", curThread);
        try
        { 
            while(socket.connected && active)
            {
                
                send(prompt);
                auto msg = cast(string)socket.readLine();
                mh.handleInput( msg );
            }

        } finally {
            ConnectionInfo.send(new ShutdownMessage());
            active = false;
        }
    }
    
    private void writeLoop()
    {
        debug writefln("%d: IGS WriteTask Started", curThread);
        while(active)
        {
            receive( (shared Message m_) {
                auto m = cast(Message)m_; //Remove shared
                if(m.supportsIGS)
                {
                    debug writefln("%d: Sending Message", curThread); 
                    m.writeIGS(socket);
                    socket.write("\r\n");
                }
            }, //Send raw messages to the client.
            (string m) {
                socket.write(m);
                socket.write("\r\n");
            });
        }
    }
    
    void spawn()
    {
        writeTask = runTask(&writeLoop);
        readTask = runTask(&readLoop);

        new JoinMessage("Earth").handleMessage(this);

        readTask.join();
        active = false;
    }

    void send( string m )
    {
        writeTask.send(m);
    }
}

class IGSMessageHandler
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
            foreach(memberFunc; __traits(allMembers, IGSMessageHandler) )
            {
                static if ( memberFunc.startsWith("cmd") )
                {
                    case memberFunc[3..$].toUpper():
                    alias ParameterTypeTuple!(MemberFunctionsTuple!(IGSMessageHandler, memberFunc)) ArgTypes;
                    ArgTypes args;
                    foreach(i, arg; ArgTypes)
                    {
                        if(i+1 == ArgTypes.length)
                            args[i] = to!arg(msg.readAll());
                        else
                            args[i] = to!arg(msg.readArg());
                    }
                    MemberFunctionsTuple!(IGSMessageHandler, memberFunc)[0](args);
                    goto end;
                }
            }
            default:
                ci.send("5 "~ cmd~": Unknown command.");
                enforce(false, "Unsupported command: " ~ cmd ~ " " ~ msg);
                break;
        }
    end:
        return;
    }
    
    void cmdJoin(string channel) {
        new JoinMessage(channel).handleMessage(ci);
    }
    
    void cmdPart(string channel)
    {
        new PartMessage(channel).handleMessage(ci);
    }

    void cmdNick(string newName)
    {
        new NickMessage(newName).handleMessage(ci);
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
