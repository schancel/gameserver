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
import ConnectionInfo;

class Channel
{
  static Channel[string] channels;

  string name;
  private bool active;
  
  private Task observer; //Observes the channel and forwards messages to clients.
  byte[ConnectionInfo] subscriptions;

  static Channel getChannel(string channelName)
  {
    if( auto p = channelName in Channel.channels )  
      {
	return (*p);
      } 
    else
      {
	return new Channel(channelName);
      }
  }
  
  this(string p_name)
  {
    active = true;
    name = p_name;
    channels[name] = this;
    observer = runTask({
	while(active) {
	  receive((MessageType m) {
	      if(active)
		foreach( subscriber; subscriptions.byKey())
		  {
		    subscriber.send(m);
		  }
	    });
	}
      });
  }

  ~this()
  {
    active = false;
  }

  void send(MessageType m)
  {
    observer.send(m);
  }

  void subscribe(ConnectionInfo conn) {
    send(["JOINED", name, conn.username]);
    subscriptions[conn] = 0;
  };

  void unsubscribe(ConnectionInfo conn) {
    send(["PARTED", name, conn.username]);
    subscriptions.remove(conn);
    if( subscriptions.length == 0)
      {
	writefln("Disposing %s", name);
	channels.remove(name);
	destroy(this);
      }
  };
}

void subscribeToChannel(ConnectionInfo conn, string channelName)
{
  Channel chan = Channel.getChannel(channelName);
  chan.subscribe(conn);
  conn.subscribe(chan);
}

void unsubscribeToChannel(ConnectionInfo conn, string channelName)
{
  Channel chan = Channel.getChannel(channelName);
  
  chan.unsubscribe(conn);
  conn.unsubscribe(chan);
}


void sendToChannel( string channelName, MessageType m)
{
  if( Channel* p = channelName in Channel.channels )  {
    (*p).send(m);
  }
}