module messages.chat;
import client.connection;

import std.typetuple;
import std.stdio;
import std.conv;

import vibe.core.stream;

import user.userinfo;
import gameserver.channels;
import messages.core;


@OpCoder(50)
class ChatMessage : Message
{
    string who;
    string channel;
    string message;

    this() pure {}

    this(string channel, string msg, string who = null ) pure
    {
        this.who = who;
        this.message = msg;
        this.channel = channel;
    }

    override void handleMessage(ConnectionInfo ci)
    {
        who = ci.user.Username; //Overwrite whatever nonsense the client might have sent with the correct name.
        
        debug writefln("%s <%s>: %s", channel, who, message );
        sendToChannel(channel, this);
    }

    override bool supportsIGS() { return true; };
    override void writeIGS(OutputStream st)
    {
        st.put( "9 !");
        st.put(who);
        st.put("!: <");
        st.put(channel );
        st.put("> " );
        st.put(message);
        st.flush();

    }
    
    mixin messages.MessageMixin!("channel", "message", "who");
}

//Private Message Format:24 *eluusive*: test
@OpCoder(51)
class PrivateMessage : Message
{
    string target;
    string who;
    string message;
    
    this() pure {}
    
    this(string target, string msg, string who = null ) pure
    {
        this.who = who;
        this.message = msg;
        this.target = target;
    }
    
    override void handleMessage(ConnectionInfo ci)
    {
        who = ci.user.Username; //Overwrite whatever nonsense the client might have sent with the correct name.
        
        debug writefln("PM <%s> --> <%s> : %s", target, who, message );
        //sendToUser(target, this);
    }
    
    override bool supportsIGS() { return true; };
    override void writeIGS(OutputStream st)
    {
        st.put( "24 *");
        st.put(who);
        st.put("* ");
        st.put(message);
        st.flush();
    }
    
    mixin messages.MessageMixin!("target", "message", "who");
}