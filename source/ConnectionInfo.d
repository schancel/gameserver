import vibe.d;
import vibe.core.core;
import vibe.core.driver;
import vibe.http.websockets;
import std.container;
import std.stdio;
import core.time;
import vibe.stream.ssl;
import vibe.core.concurrency;
import vibe.core.log;
import std.conv;
import vibe.stream.operations;
import vibe.data.json;

import Messaging;
import Channels;

class ConnectionInfo
{ 
  private Task writeTask, readTask;
  bool active;
  string username = "AnonymousCoward";
  byte[Channel] subscriptions;
  ulong curThread;
  MessageHandler mh;

  this()
  {
    active = true;
    mh = new MessageHandler(this);
  }

  ~this()
  {
    debug writefln("%d: disconnected", curThread);
    foreach( sub; subscriptions.byKey() )
      {
	sub.unsubscribe(this);
      }
  }

  void broadcast( MessageType m )
  {
    foreach( chan; subscriptions.byKey() )
      chan.send(m);
  }

  void send( MessageType m )
  {
    writeTask.send(m);
  }

  void subscribe(Channel chan) {
    subscriptions[chan] = 0;
  };

  void unsubscribe(Channel chan) {
    subscriptions.remove(chan);
  };
}

/****************************************************************************************

*****************************************************************************************/
class WebsocketConnection : ConnectionInfo
{ 
  private WebSocket socket;

  this(WebSocket _conn)
  {
    super();
    socket = _conn;
    curThread = socket.toHash();
  }

  void readLoop()
  {
    while(socket.connected)
      {
	Json JsonMsg;
	try
	  {
	    JsonMsg = parseJsonString(socket.receiveText());
	    mh.handleMessage( JsonMsg );
	  }
	catch( Exception ex )
	  {
	    debug writeln(ex.msg);
	  }
      } 
    send(null);
    active = false;
  }
  
  private void writeLoop()
  {
    debug writefln("%d: writetask", curThread);
    while(active)
      {
	receive( (MessageType m) {
	    debug writefln("%d: Sending Message", curThread); 
	    if ( m )
	      socket.send(serializeToJson(m).toString);
	  });
      }
  }
  
  void spawn()
  {
    readTask = runTask(&readLoop);
    writeTask = runTask(&writeLoop);
    readTask.join();
    active = false;
  }
}


/****************************************************************************************

*****************************************************************************************/
class TelnetConnection : ConnectionInfo
{ 
  TCPConnection socket;

  this(TCPConnection _conn)
  {
    super();
    socket = _conn;
    curThread = 1; //TODO: Fix this
  }

  ~this()
  {
    debug writefln("%d: disconnected", curThread);
    foreach( sub; subscriptions.byKey() )
      {
	sub.unsubscribe(this);
      }
  }

  void readLoop()
  {
    while(socket.connected)
      {
	Json JsonMsg;
	try
	  {           
            writefln("WTF" );

            auto msg = socket.readAllUTF8();
	    JsonMsg = parseJsonString(msg);
	    mh.handleMessage( JsonMsg );
            writefln("WTF %s", msg );
	  }
	catch( Exception ex )
	  {
	     writeln(ex.msg);
	  }
      } 
    send(null);
    active = false;
  }
  
  private void writeLoop()
  {
    debug writefln("%d: writetask", curThread);
    while(active)
      {
	receive( (MessageType m) {
	    debug writefln("%d: Sending Message", curThread); 
	    if ( m )
	      socket.write(serializeToJson(m).toString);
	  });
      }
  }
  
  void spawn()
  {
    readTask = runTask(&readLoop);
    writeTask = runTask(&writeLoop);

    readTask.join();
    active = false;
  }
}