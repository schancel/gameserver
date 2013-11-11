module client.messages;
import client.connection;


import vibe.core.stream;

import user.userinfo;
import std.typecons;
import msgpack;

///Attribute struct to identify what the opcode for a particular message in the protocol is.
struct OpCoder
{
    ubyte opCode;
}

///Mixin to create a virtual function which returns the opcode of the class.
mixin template MessageMixin(Args...)
{
    override ubyte opCode()
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

    //mixin MessagePackable!(Args);
}
//

@OpCoder(0)
class Message
{
    void handleMessage(ConnectionInfo ci ) 
    {

    }

    bool supportsIGS() { return false; }
    
    string toIGSString() { return null; }

    ubyte opCode() { return 0; }

    static ubyte opCodeStatic() { return 0; }
}

@OpCoder(1)
class JoinMessage : Message
{
    string channel;

    this(string channel) pure 
    {
        this.channel = channel;
    }

    this() pure { }

    mixin client.messages.MessageMixin!("channel");
}

@OpCoder(2)
class ChatMessage : Message
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

    mixin client.messages.MessageMixin!("user","channel","message");
}

@OpCoder(3)
class ShutdownMessage : Message
{
    this() pure
    {
    }
    mixin client.messages.MessageMixin;
}

alias hack(alias t) = t;

void serialize(T)(OutputStream st, T msg) if ( is(T == Message) )
{
    st.write([msg.opCode]);
    switch( msg.opCode ){
        foreach( ele; __traits(allMembers, client.messages))
        {
            alias eleMen = hack!(__traits(getMember, client.messages, ele));
            static if ( is( eleMen : Message ) )
            {
                case eleMen.opCodeStatic:
                eleMen temp = cast(eleMen)msg;
                st.write(msgpack.pack!(true)(temp));
                break;
            }
        }
        default:
            break;
    }
}

void serialize(T)(OutputStream st, T msg) if ( is(T : Message) && !is(T == Message) )
{
    ubyte[] ret;
    st.write([msg.opCode]);
    st.write(msgpack.pack!(true)(msg));
}

unittest
{
    auto foo = new JoinMessage();
    Message fooHidden = foo;
    //assert( serialize(foo) == serialize(fooHidden) ); // Doesn't work since we don't have a stream
    //TODO: Correct the unittest.
}

Message deserialize(ubyte[] msg) {
    import std.exception;
    enforce(msg.length > 1, "Msg too short");
    ubyte code = msg[0];
    msg = msg[1..$];
    Message ret;

    switch( code ){
        foreach( ele; __traits(allMembers, client.messages))
        {
            alias eleMen = hack!(__traits(getMember, client.messages, ele));

            static if ( is( eleMen : Message ) )
            {
                import std.stdio;
                case eleMen.opCodeStatic:
                eleMen temp = new eleMen();
                debug writeln(ele, msgpack.pack!(true)(new JoinMessage("Earth")));
                debug writeln(ele, msg);
                msgpack.unpack(msg, temp);
                ret = temp;
                break;
            }
        }
        default:
            ret = null;
    }
    return ret;
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


mixin(GenEnum("OpCode"));
