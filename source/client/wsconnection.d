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
        user = new shared UserInfo();
        curThread = socket.toHash();
    }

    void readLoop()
    {
        while(socket.connected)
        {
            try
            {
                auto msg = socket.receiveText();
                //mh.handleMessage( msg );
            }
            catch( Exception ex )
            {
                debug writeln(ex.msg);
            }
        } 
        send(new shared(ShutdownMessage));
        active = false;
    }
    
    private void writeLoop()
    {
        debug writefln("%d: writetask", curThread);
        while(active)
        {
            receive( (shared Message m) {
                debug writefln("%d: Sending Message", curThread); 

                socket.write(m.toString);
                socket.write(" ");
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