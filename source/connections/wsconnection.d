module connections.wsconnection;

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
import vibe.core.log;

import msgpack;  //Msg Pack For messages

import connections.core;

import messages;

import channels;
import user.userinfo;

/****************************************************************************************

 *****************************************************************************************/
class WSConnection : ConnectionBase
{ 
    private WebSocket socket;

    this(WebSocket _conn)
    {
        super();
        socket = _conn;
        userinfo = new UserInfo();
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
                    try {
                        msg.handleMessage(this);
                    } catch( Exception e)
                    {
                        send(new ErrorMessage(e.msg));
                    }
                }
            }
        } catch( Exception e) {
            active = false;
        }
    }

    private void writeLoop()
    {
        logDebug("%d: writetask", curThread);
        try {
            while(active)
            {
                receive( (shared Message m_) {
                    auto m = cast(Message)m_; //Remove shared.  
                    //Could use lock() but that would block other threads from reading.  Nobody should be mutating the message anyways.

                    logDebug("%s: Sending Message", userinfo.Username); 
                    socket.send( (scope OutgoingWebSocketMessage os) { 
                        serialize(os, m);
                    }, FrameOpcode.binary);
                    
                    
                });
            }
        } catch (InterruptException e)
        {
            //Shutting down;
        }
    }

    void spawn()
    {
        writeTask = runTask(&writeLoop);
        readTask = runTask(&readLoop);

        readTask.join();
        active = false;
        writeTask.interrupt();
    }
}
