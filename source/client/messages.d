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
template opCode()
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
}

@OpCoder(1)
class JoinMessage : Message
{
    this() pure 
    {
    }

    mixin client.messages.opCode;
}

@OpCoder(2)
class ChatMessage : Message
{
    UserInfo user;
    string channel;
    string message;

    this(UserInfo user, string channel, string msg ) pure
    {
        this.user = user;
        this.message = msg;
        this.channel = channel;
    }

    this() pure
    {

    }

    mixin client.messages.opCode;
}

@OpCoder(3)
class ShutdownMessage : Message
{
    this() pure
    {
    }
    mixin client.messages.opCode;
}

alias hack(alias t) = t;


void serialize(T)(OutputStream st, T msg) if ( is(T == Message) )
{
    st.write([msg.opCode]);
    switch( msg.opCode ){
        alias parent = hack!(__traits(parent, OpCoder));
        foreach( ele; __traits(allMembers, parent))
        {
            alias eleMen = hack!(__traits(getMember, parent, ele));
            foreach( tra; __traits(getAttributes, eleMen))
            {
                static if ( is( typeof(tra) == OpCoder ) )
                {
                    case tra.opCode:
                    eleMen temp = cast(eleMen)msg;
                    st.write(msgpack.pack(temp));
                    break;
                }
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
    st.write(msgpack.pack(msg));
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
        alias parent = hack!(__traits(parent, OpCoder));
        foreach( ele; __traits(allMembers, parent))
        {
            alias eleMen = hack!(__traits(getMember, parent, ele));
            foreach( tra; __traits(getAttributes, eleMen))
            {
                static if ( is( typeof(tra) == OpCoder ) )
                {
                    case tra.opCode:
                    eleMen temp = new eleMen();
                    msgpack.unpack!(eleMen)(msg, temp);
                    ret = temp;
                    break;
                }
            }
        }
        default:
            ret = null;
    }
    return ret;
}


string GenEnum(string Name) {
    bool needsComma = false;
    string code = "enum " ~ Name ~ " {";
    alias parent = hack!(__traits(parent, OpCoder));
    foreach( ele; __traits(allMembers, parent))
    {
        alias eleMen = hack!(__traits(getMember, parent, ele));
        foreach( tra; __traits(getAttributes, eleMen))
        {
            static if ( is( typeof(tra) == OpCoder ) )
            {
                import std.conv;
                code ~= (needsComma ? "," : "") ~ ele ~ "=" ~ to!string(tra.opCode) ;
                needsComma = true;
            }
        }
    }
    code ~= " }";
    return code;
}


mixin(GenEnum("OpCode"));
