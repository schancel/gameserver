module client.messages;
import client.connection;

import user.userinfo;
import std.typecons;
import msgpack;

struct OpCoder
{
    ubyte opCode;
}

class Message
{
    void handleMessage(ConnectionInfo ci ) 
    {

    }

    bool supportsIGS() { return false; }
    
    string toIGSString() { return null; }
}

@OpCoder(1)
class JoinMessage : Message
{
    this() pure shared
    {
    }
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
}

@OpCoder(3)
class ShutdownMessage : Message
{
    this() pure
    {
    }
}

alias hack(alias t) = t;


/*** 
 * Desired output:
 * enum OpCode : ubyte
 * {
 *     None = 0,
 *     JoinMessage = 1,
 *     ChatMessage = 2,
 *     ShutdownMessage = 3
 * }
 */
string GenEnum(string Name) {
    bool needsComma = false;
    string foo = "enum " ~ Name ~ " {";
    alias parent = hack!(__traits(parent, OpCoder));
    foreach( ele; __traits(allMembers, parent))
    {
        alias eleMen = hack!(__traits(getMember, parent, ele));
        foreach( tra; __traits(getAttributes, eleMen))
        {
            static if ( is( typeof(tra) == OpCoder ) )
            {
                import std.conv;
                foo ~= (needsComma ? "," : "") ~ ele ~ "=" ~ to!string(tra.opCode) ;
                needsComma = true;
            }
        }
    }
    foo ~= " }";
    return foo;
}


//TODO: Made this not allocate more than necessary.  Surely we can write the needed byte, and then write the rest to the socket?
ubyte[] serialize(T)(T msg) {
    ubyte[] ret;
    foreach( tra; __traits(getAttributes, typeof(msg)))
    {
        static if ( is( typeof(tra) == OpCoder ) )
        {
            ret ~= tra.opCode;
            ret ~= msgpack.pack(msg);
            return ret;
        }
    }
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


mixin(GenEnum("OpCode"));
