module client.messages;

import user.userinfo;
import std.typecons;
import msgpack;


/*** 
 * Desired output:
 * enum OpCode : ubyte
 * {
 *     None = 0,
 *     Join = 1,
 *     ChatMessage = 2,
 *     Shutdown = 3
 * }
 */

struct OpCoder
{
    ubyte opCode;
}

@OpCoder(1)
shared class JoinMessage : IMessage
{
    this()
    {
    }
    }

@OpCoder(2)
shared class ChatMessage : IMessage
{
    UserInfo user;
    string channel;
    string message;

    this(shared UserInfo user, string channel, string msg ) 
    {
        this.user = user;
        this.message = msg;
        this.channel = channel;
    }

    this()
    {

    }
}

@OpCoder(3)
shared class ShutdownMessage : IMessage
{
    this()
    {
    }
}

alias hack(alias t) = t;

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

shared(IMessage) deserialize(ubyte[] msg) {
    import std.exception;
    enforce(msg.length > 1, "Msg too short");
    ubyte code = msg[0];
    msg = msg[1..$];
    shared IMessage ret;

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
                    shared eleMen temp = new shared eleMen();
                    msgpack.unpack!(shared eleMen)(msg, temp);
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

shared interface IMessage
{
}
