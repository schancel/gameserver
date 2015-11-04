module messages.chat;

import std.typetuple;
import std.stdio;
import std.conv;

import vibe.core.stream;
import vibe.core.log;

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
        
        logDebug("%s <%s>: %s", channel, who, message );
        sendToChannel(channel, this);
    }

    override bool supportsIGS() { return true; };
    override void writeIGS(OutputStream st)
    {
        import vibe.stream.wrapper;
        auto stor = StreamOutputRange(st);
        stor.put((cast(int)IGS_CODES.SHOUT).to!string);
        stor.put( " !");
        stor.put(who);
        stor.put("!: <");
        stor.put(channel );
        stor.put("> " );
        stor.put(message);
        st.flush();
    }
    
    mixin messages.MessageMixin!("channel", "message", "who");
}

//Private Message Format:24 *eluusive*: test
@OpCoder(51)
class PrivateMessage : Message
{
    string target;
    string message;
    string who;

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
        
        logDebug("PM <%s> --> <%s> : %s", target, who, message );
        try {
            sendToUser(target, this);
            ci.send(this);
        } catch (Exception e)
        {
            //TODO: Queue up messages in database.
            enforce(false, "User is offline, or doesn't exist.");
        }
    }
    
    override bool supportsIGS() { return true; };
    override void writeIGS(OutputStream st)
    {
        import vibe.stream.wrapper;
        auto stor = StreamOutputRange(st);
        stor.put( (cast(int)IGS_CODES.TELL).to!string );
        stor.put(" *");
        stor.put(who);
        stor.put("* ");
        stor.put(message);
        st.flush();
    }
    
    mixin messages.MessageMixin!("target", "message", "who");
}