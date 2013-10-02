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
import vibe.data.json;

import Messaging;
import Channels;

class ConnectionInfo
{ 
  private Task writeTask, readTask;
  bool active;
  string username = "AnonymousCoward";
  byte[Channel] subscriptions;
  private WebSocket socket;
  ulong curThread;
  MessageHandler mh;

  this(WebSocket _conn)
  {
    active = true;
    socket = _conn;
    curThread = socket.toHash();
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
    writeTask = runTask(&writeLoop);
    readTask = runTask(&readLoop);
    scope(exit) {
      readTask.join();
      active = false;
    }
  }

  void subscribe(Channel chan) {
    subscriptions[chan] = 0;
  };

  void unsubscribe(Channel chan) {
    subscriptions.remove(chan);
  };
}