module client.messages;
import client.connection;

import std.typecons;
import std.stdio;
import std.conv;

import vibe.core.stream;
import msgpack;

import user.userinfo;
import gameserver.channels;

///Attribute struct to identify what the opcode for a particular message in the protocol is.
struct OpCoder
{
    ubyte opCode;
}

///Mixin to create a virtual function which returns the opcode of the class.
mixin template MessageMixin(Args...)
{
    override ubyte opCode() const
    {
        foreach( tra; __traits(getAttributes, typeof(this)))
        {
            static if ( is( typeof(tra) == OpCoder ) )
            {
                return tra.opCode;
            }
        }
        assert(0, "No opcode class" );
    }

    static ubyte opCodeStatic()
    {
        foreach( tra; __traits(getAttributes, typeof(this)))
        {
            static if ( is( typeof(tra) == OpCoder ) )
            {
                return tra.opCode;
            }
        }
        return 0;
    }

    static string jsBinding()
    {
        string code = "ServerConnection.prototype." ~ typeof(this).stringof[0..$-"Message".length]~ " = function (";
        bool needsComma = false;
        foreach(arg; Args)
        {
            if(needsComma) code ~= ",";
            code ~=  arg; 
            needsComma= true;
        }

        code ~= ") { this.doSend(" ~ to!string(typeof(this).opCodeStatic) ~ ", [";

        needsComma = false;
        foreach(arg; Args)
        {
            if(needsComma) code ~= ",";
            code ~=  arg; 
            needsComma= true;
        }

        code ~= "]); }\n"; //Can't use js arguments.  It's an object type not an array.

        return code;
    }

    mixin MessagePackable!(Args);
}
//
class Message
{
    void handleMessage(ConnectionInfo ci ) 
    {

    }

    bool supportsIGS() { return false; }
    
    string toIGSString() { return ""; }

    ubyte opCode() const { return 0; } 

    static ubyte opCodeStatic() { return 0; }
}

@OpCoder(1)
class ShutdownMessage : Message
{
    this() pure
    {
    }
    mixin client.messages.MessageMixin;
}

@OpCoder(40)
class JoinMessage : Message
{
    string channel;

    this(string channel) pure 
    {
        this.channel = channel;
    }

    this() pure { }

    override void handleMessage(ConnectionInfo ci)
    {
        writefln("%s: Joined channel %s", ci.user.Username, channel);
        sendToChannel(channel, this);
        subscribeToChannel( ci, channel );
    }

    mixin client.messages.MessageMixin!("channel");
}

@OpCoder(41)
class JoinedMessage : Message
{
    string channel;
    string who;
    
    this(string channel, string who) pure 
    {
        this.channel = channel;
        this.who = who;
    }
    
    this() pure { }
    
    mixin client.messages.MessageMixin!("channel");
}

@OpCoder(10)
class OutgoingMessage : Message
{
    string user;
    string channel;
    string message;

    this(string user, string channel, string msg ) pure
    {
        this.user = user;
        this.message = msg;
        this.channel = channel;
    }

    this() pure
    {

    }

    mixin client.messages.MessageMixin!("user", "channel", "message");
}

@OpCoder(11)
class IncomingMessage : Message
{
    string target;
    string message;
    
    this(string target, string msg ) pure
    {
        this.message = msg;
        this.target = target;
    }
    
    this() pure
    {
        
    }
    
    mixin client.messages.MessageMixin!("target", "message");
}


alias hack(alias t) = t; //Hack to be able to store __traits stuff in a tuple

void serialize(T)(OutputStream st, inout(T) msg) if ( is(T  == Message) )
{
    st.write([msg.opCode]); //TODO: Fix this so it doesn't allocate
    switch( msg.opCode ){
        foreach( ele; __traits(allMembers, client.messages))
        {
            alias eleMen = hack!(__traits(getMember, client.messages, ele));
            static if ( is( eleMen : Message ) )
            {
                case eleMen.opCodeStatic:
                eleMen temp = cast(eleMen)msg;
                st.write(msgpack.pack(temp));
                break;
            }
        }
        default:
            break;
    }
}

void serialize(T)(OutputStream st, inout(T) msg) if ( is(T : Message) && !is(T == Message) )
{
    ubyte[] ret;
    st.write([msg.opCode]);
    st.write(msgpack.pack(msg));
}


Message deserialize(ubyte[] msg) {
    import std.exception;
    enforce(msg.length > 1, "Msg too short");
    ubyte code = msg[0];
    msg = msg[1..$];

    switch( code ){
        foreach( ele; __traits(allMembers, client.messages))
        {
            alias eleMen = hack!(__traits(getMember, client.messages, ele));

            static if ( is( eleMen : Message ) )
            {
                case eleMen.opCodeStatic:
                eleMen temp = new eleMen();
                msgpack.unpack(msg, temp);
                return temp;
            }
        }
        default:
            enforce(false, "Invalid opcode: " ~ to!string(code));
    }

    return null;
}

unittest
{
    import std.stdio;
    auto temp = new JoinMessage("Earth");
    msgpack.unpack(msgpack.pack(temp), temp);
    writeln("Unpacked!");

    msgpack.unpack!(true)(msgpack.pack!(true)(temp), temp);
    writeln("Unpacked?");
}


string GenEnum(string Name) {
    bool needsComma = false;
    string code = "enum " ~ Name ~ " {";
    foreach( ele; __traits(allMembers, client.messages))
    {
        alias eleMen = hack!(__traits(getMember, client.messages, ele));

        static if ( is( eleMen : Message ) )
        {
            import std.conv;
            code ~= (needsComma ? "," : "") ~ ele ~ "=" ~ to!string(eleMen.opCodeStatic) ;
            needsComma = true;
        }
    }
    code ~= " }";
    return code;
}

string JavascriptBindings() {
    string code = "OpCodes = {};";
    foreach( ele; __traits(allMembers, client.messages))
    {
        alias eleMen = hack!(__traits(getMember, client.messages, ele));
        
        static if ( is( eleMen : Message ) && !is( eleMen == Message) )
        {
            import std.conv;
            code ~= "OpCodes." ~ ele ~ "=" ~ to!string(eleMen.opCodeStatic) ~";\n" ;
            code ~= eleMen.jsBinding();
        }
    }
    return code;
}


mixin(GenEnum("OpCode"));
