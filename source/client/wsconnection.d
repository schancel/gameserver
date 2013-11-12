module client.wsconnection;

import std.container;
import std.stdio;
import core.time;
import std.conv;

import vibe.core.core;
import vibe.core.driver;
import vibe.http.server;
import vibe.http.websockets;
import vibe.core.concurrency;
import vibe.stream.operations;

import msgpack;  //Msg Pack For messages

import client.connection;
import client.messages;
import gameserver.channels;
import user.userinfo;

/****************************************************************************************

 *****************************************************************************************/
class WSConnection : ConnectionInfo
{ 
    private WebSocket socket;

    this(WebSocket _conn)
    {
        super();
        socket = _conn;
        user = new UserInfo();
        curThread = socket.toHash();
    }

    void readLoop()
    {
        while(socket.connected)
        {
            try
            {
                import std.stdio;
                auto msgData = socket.receiveBinary();
                auto msg = deserialize(msgData);
                if(msg !is null) 
                {
                    msg.handleMessage(this);
                }
            }
            catch( Exception ex )
            {
                debug writeln(ex.msg);
            }
        } 
        send(new ShutdownMessage);
        active = false;
    }

    private void writeLoop()
    {
        debug writefln("%d: writetask", curThread);
        while(active)
        {
            receive( (shared Message m_) {
                auto m = cast(Message)m_; //Remove shared.  
                //Could use lock() but that would block other threads from reading.  Nobody should be mutating the message anyways.

                debug writefln("%s: Sending Message", user.Username); 

                socket.send( (scope OutgoingWebSocketMessage os) { 
                    serialize(os, m);
                }, FrameOpcode.binary);
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
