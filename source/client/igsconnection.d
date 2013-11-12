module client.igsconnection;

import std.container;
import std.stdio;
import core.time;
import std.conv;
import std.array : join;
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

import client.connection;
import gameserver.channels;
import user.userinfo;
import util.util;
import client.messages;
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

        socket.write("Login: ");
        socket.readLine();
        socket.write("Password: ");
        socket.readLine();

        user = new UserInfo();
    }

    void readLoop()
    {
        debug writefln("%d: IGS ReadTask Started", curThread);
        while(socket.connected)
        {
            try
            {
                //send(new ChatMessage("1 5"));
                auto msg = cast(string)socket.readLine();
                mh.handleInput( msg );
            }
            catch( Exception ex )
            {
                writeln(ex.msg);
            }
        } 
        send(new ShutdownMessage());
        active = false;
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
                    socket.write(m.toIGSString());
                    socket.write("\r\n");
                }
            });
        }
    }
    
    void spawn()
    {
        writeTask = runTask(&writeLoop);
        readTask = runTask(&readLoop);

        readTask.join();
        active = false;
    }
}

class IGSMessageHandler
{
    private ConnectionInfo ci;
    
    this(ConnectionInfo _ci)
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
                enforce(false, "Unsupported command: " ~ cmd);
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

    void cmdMsg(string channel, string message)
    {
        new ChatMessage(channel,message).handleMessage(ci);
    }

    void cmdWho(string channel)
    {
        new WhoMessage(channel).handleMessage(ci);
    }
}
