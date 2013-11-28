module messages.chat;

import std.typetuple;
import std.stdio;
import std.conv;

import vibe.core.stream;

import connections;
import user.userinfo;
import channels;
import messages.core;
import user;

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

    override void handleMessage(Connection ci)
    {
        who = ci.userinfo.Username; //Overwrite whatever nonsense the client might have sent with the correct name.
        
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
    
    override void handleMessage(Connection ci)
    {
        who = ci.userinfo.Username; //Overwrite whatever nonsense the client might have sent with the correct name.
        
        debug writefln("PM <%s> --> <%s> : %s", target, who, message );
        try {
            sendToUser(target, this);
        } catch (Exception e)
        {
            writefln("TODO: Implement notifying user of offline target");
        }
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