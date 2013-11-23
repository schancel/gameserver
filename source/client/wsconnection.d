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

import messages;

import gameserver.channels;
import user.userinfo;

/****************************************************************************************

 *****************************************************************************************/
class WSConnection : ConnectionInfo
{ 
    private WebSocket socket;
    string SecWebSocketKey;

    this(WebSocket _conn, string SecWebSocketKey)
    {
        super();
        socket = _conn;
        user = new UserInfo();
        this.SecWebSocketKey = SecWebSocketKey;
        writeln(SecWebSocketKey);
        curThread = socket.toHash();
    }

    void readLoop()
    {
        try
        {
            while(socket.connected)
            {
                
                import std.stdio;
                auto msgData = socket.receiveBinary();
                auto msg = deserialize(msgData);
                if(msg !is null) 
                {
                    msg.handleMessage(this);
                }
            }
        } finally {
            active = false;
            send(new ShutdownMessage);
        }
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
