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

import Channels;
import ConnectionInfo;

public alias immutable(string)[] MessageType;

public enum MessageTypes : string
{
  kJoin = "JOIN",
    kPart = "PART",
    kTell = "TELL",
    kWho = "WHO",
    kNick = "NICK",
    kMsg = "MSG",
    kQuit = "QUIT"
    }

void handleMessage( ConnectionInfo ci, MessageType m)
{
  enforce(m.length > 1, "Invalid message");
  
  switch( m[0] )
    {
    case MessageTypes.kJoin:
      enforce(m.length == 2);
      writefln("%s: Joined channel %s", ci.username, m[1]);
      ci.send(m);
      subscribeToChannel( ci, m[1] );
      break;

    case MessageTypes.kPart:
      enforce(m.length == 2);
      writefln("%s: Parted channel %s", ci.username, m[1]);
      ci.send(m);
      unsubscribeToChannel( ci, m[1] );
      break;

    case MessageTypes.kNick:
      enforce(m.length == 2);
      writefln("%s: Changed name to %s ", ci.username, m[1]);
      ci.username = m[1];
      break;

    case MessageTypes.kMsg:
      enforce(m.length == 3);
      writefln("%s: Sent message to #%s: %s", ci.username, m[1], m[2]);
      sendToChannel(m[1], m ~ ci.username);
      break;

    case MessageTypes.kWho:
      enforce(m.length == 2);
      writefln("%s: WHO #%s", ci.username, m[1]);
      string[] who = [];
      foreach(curCi; Channel.getChannel(m[1]).subscriptions.byKey())
	who ~= curCi.username;
      ci.send([MessageTypes.kMsg, m[1], who.join(","), "Userlist"]);
      
      break;

    default:
      break;
    }
  
}