module messages.core;

import client.connection;

import std.typetuple;
import std.stdio;
import std.conv;

import vibe.core.stream;

public import msgpack;

import messages.auth;
import messages.chat;
import messages.channel;

///Attribute struct to identify what the opcode for a particular message in the protocol is.
struct OpCoder
{
    ubyte opCode;
}

///Mixin to create a virtual function which returns the opcode of the class.
mixin template MessageMixin(Args...)
{
    ///Return the opCode of the class for deserialization purposes.  Needs to be a virtual function.
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

    ///Obtain the current class' opcode and return it for compile-time reflection.
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

    ///Generate a javascript RPC stub for the a class.
    static string jsBinding()
    {
        //memberFunc.endsWith("Message")
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


///Base message class.   This class should not be serialized or de-serialized.
class Message
{
    this() pure {}
    void handleMessage(ConnectionInfo ci ) { assert(false, "Not implemented");   }
    bool supportsIGS() { return false; }
    void writeIGS(OutputStream st) { assert(false, "Not implemented");    }
    ubyte opCode() const { assert(false, "Not implemented");    } 
}

//Begin serialization code

///This function serializes messages to a Vibe-D OutputStream with the first item being the opCode for the message type.
void serialize(T)(OutputStream st, inout(T) msg) if ( is(T == Message) )
{
    st.put(msg.opCode); 
    switch( msg.opCode ){
        foreach( messageType; AllMessages!()){
            case messageType.opCodeStatic:
            messageType temp = cast(messageType)msg;
            st.write(msgpack.pack(temp));
            break;
        }
        default:
            break;
    }
}

///See above,  this is a specialized version for when we already know the type at compile-time.
void serialize(T)(OutputStream st, inout(T) msg) if ( is(T : Message) && !is(T == Message) )
{
    ubyte[] ret;
    st.put(msg.opCode); 
    st.write(msgpack.pack(msg));
}

///Deserialize a message.  Expects the first byte to be the message's opCode.   
///The rest is then fed into msgpack.unpack for the appropriate message.
Message deserialize(ubyte[] msg) {
    import std.exception;
    enforce(msg.length > 1, "Msg too short");
    ubyte code = msg[0];
    msg = msg[1..$];

    switch( code ){
        foreach( messageType; AllMessages!()){
            case messageType.opCodeStatic:
            messageType temp = new messageType();
            msgpack.unpack(msg, temp);
            return temp;
        }
        default:
            enforce(false, "Invalid opcode: " ~ to!string(code));
    }

    return null;
}


///Generate the code for an enum at compile time.  May be useful in various code so as to not hard-code the opcodes anywhere but in the
///actual message attribute.
string GenEnum(string Name) {
    bool needsComma = false;
    string code = "enum " ~ Name ~ " {";
    foreach( messageType; AllMessages!()){
        import std.conv;
        code ~= (needsComma ? "," : "") ~ __traits(identifier,messageType) ~ "=" ~ to!string(messageType.opCodeStatic) ;
        needsComma = true;
    }
    code ~= " }";
    return code;
}

mixin(GenEnum("OpCode"));

///Generate javascript code for the client so as to not hardcode opcodes both places, or generate endless stub RPC functions.
///This should be bound to a URL with the vibe-d router.
string JavascriptBindings() {
    string code = "OpCodes = {};";
    foreach( messageType; AllMessages!())
    {
        import std.conv;
        code ~= "OpCodes." ~ __traits(identifier,messageType) ~ "=" ~ to!string(messageType.opCodeStatic) ~";\n" ;
        code ~= messageType.jsBinding();
    }

    return code;
}


alias hack(alias T) = T; //Hack to be able to store __traits stuff in a tuple


///Template to generate a TypeTuple of all message types;
template AllMessages()
{
    alias AllMessages = TypeTuple!( MessagePackage!(messages.auth),
                                    MessagePackage!(messages.chat),
                                    MessagePackage!(messages.channel));
}

template MessagePackage(alias packageName)
{
    alias Members = TypeTuple!(__traits(allMembers, packageName));
    alias MessagePackage = PackageMessages!(packageName, Members)[0..$-1]; //Strip off the Last Item.
}

template PackageMessages(alias packageName, Members...)
{
    //pragma(msg, Members);
    alias member = hack!(__traits(getMember, packageName, Members[0]));
    static if ( is( member : Message ) && !is( member == Message))
    {
        static if( Members.length == 1)
        {
            alias PackageMessages = hack!(member);
        } else {
            alias PackageMessages = TypeTuple!(hack!(member), PackageMessages!(packageName, Members[1..$]));
        }
    } else {
        static if( Members.length == 1)
        {
            alias PackageMessages = TypeTuple!(void);
        } else {
            alias PackageMessages = TypeTuple!(PackageMessages!(packageName, Members[1..$]));
        }
    }
}

