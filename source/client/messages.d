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

///Sent this message to initiate a close of the connection.
@OpCoder(1)
class ShutdownMessage : Message
{
    this() pure {}

    mixin client.messages.MessageMixin;
}

///Handles allowing user to change their name.   This needs to be changed to an authentication 
///message in the future.
@OpCoder(5)
class NickMessage : Message
{
    string oldName;
    string newName;
    
    this() pure {}
    
    this(string newName, string oldName = "") pure 
    {
        this.newName = newName;
        this.oldName = oldName;
    }
    
    override void handleMessage(ConnectionInfo ci)
    {
        oldName = ci.user.Username; //Overwrite whatever nonsense the client might have sent with the correct name.
        
        debug writefln("%s: Changed name to %s ", ci.user.Username, newName);
        ci.user.Username = newName;
    }
    
    mixin client.messages.MessageMixin!("newName", "oldName");
}

@OpCoder(40)
class JoinMessage : Message
{
    string channel;
    string who;

    this() pure {}

    this(string channel, string who = null) pure 
    {
        this.channel = channel;
        this.who = who;
    }

    override void handleMessage(ConnectionInfo ci)
    {
        who = ci.user.Username; //Overwrite whatever nonsense the client might have sent with the correct name.

        debug writefln("%s: Joined channel %s", who, channel);
        subscribeToChannel( ci, channel );
        sendToChannel(channel, this);
    }
    
    mixin client.messages.MessageMixin!("channel", "who");
}

@OpCoder(41)
class PartMessage : Message
{
    string channel;
    string who;

    this() pure {}

    this(string channel, string who = null) pure 
    {
        this.channel = channel;
        this.who = who;
    }
 
    override void handleMessage(ConnectionInfo ci)
    {
        who = ci.user.Username; //Overwrite whatever nonsense the client might have sent with the correct name.
        
        debug writefln("%s: Parted channel %s", who, channel);
        unsubscribeToChannel( ci, channel );
        sendToChannel(channel, this);
    }
    
    mixin client.messages.MessageMixin!("channel", "who");
}

@OpCoder(45)
class WhoMessage : Message
{
    string channel;

    this() pure {}

    this(string channel) pure 
    {
        this.channel = channel;
    }

    override void handleMessage(ConnectionInfo ci)
    {
        debug writefln("%s: Requested users of channel %s", ci.user.Username, channel);
        new WhoListMessage(channel).handleMessage(ci);
    }

    mixin client.messages.MessageMixin!("channel");
}

@OpCoder(46)
class WhoListMessage : Message
{
    string[] whoList;
    string channel;
    
    this() pure {}
    
    this(string channel) pure 
    {
        this.channel = channel;
    }

    override void handleMessage(ConnectionInfo ci)
    {
        foreach(curCi; Channel.getChannel(channel).subscriptions.byKey())
            whoList ~= curCi.user.Username;

        ci.send(this);
    }

    override bool supportsIGS() { return true; };

   /***  Output should look like this for other clients to parse it.
27  Info       Name       Idle   Rank |  Info       Name       Idle   Rank
27  QX --   -- isfadm02   27s     2k  |   X --   -- zz0008      1m     NR 
27   X256   -- guest4389   3m     NR  |   X --   -- AutoDone   35s     2k 
27  QX --   -- livegw8     0s     NR  |  QX --   -- livegw7    58s     NR 
27  QX --   -- livegw9     1m     NR  |  QX --   -- livegw10   56s     NR 
27  QX --   -- livegw13   36s     NR  |  SX --   -- zz0004      3s     NR 
27  QX --   -- livegw6     5s     NR  |  QX --   -- livegw5     5s     NR 
27  QX --   -- livegw12   44s     NR  |  QX --   -- livegw11    1m     NR 
27  Q  --   -- guest6427   3m     NR  |  QX --   -- haras      48s     3k*
27  Q  --   -- guest9823   1m     NR  |  Q  --   -- guest7670   3s     NR 
27  QX --   -- livegw4    31s     NR  |   X --   -- crocblanc   1m     7k*
*/

    override void writeIGS(OutputStream st)
    {
        int line = 0;
        st.put("27  Info       Name       Idle   Rank |  Info       Name       Idle   Rank");
        foreach(i, who; whoList)
        {
            if( i % 2 == 1)
                st.put("  |");
            else 
                st.put("\r\n27 ");
            st.put("    --   -- " ~ who ~ "    0s     NR");
        }
        st.flush();
    }

 
    mixin client.messages.MessageMixin!("channel", "whoList");
}

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
    
    mixin client.messages.MessageMixin!("channel", "message", "who");
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
    
    mixin client.messages.MessageMixin!("target", "message", "who");
}

//Begin serialization code

alias hack(alias t) = t; //Hack to be able to store __traits stuff in a tuple


///This function serializes messages to a Vibe-D OutputStream with the first item being the opCode for the message type.
void serialize(T)(OutputStream st, inout(T) msg) if ( is(T  == Message) )
{
    st.put(msg.opCode); 
    switch( msg.opCode ){
        foreach( ele; __traits(allMembers, client.messages))
        {
            alias eleMen = hack!(__traits(getMember, client.messages, ele));
            static if ( is( eleMen : Message ) && !is( eleMen == Message) )
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
        foreach( ele; __traits(allMembers, client.messages))
        {
            alias eleMen = hack!(__traits(getMember, client.messages, ele));

            static if ( is( eleMen : Message ) && !is( eleMen == Message) )
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


///Generate the code for an enum at compile time.  May be useful in various code so as to not hard-code the opcodes anywhere but in the
///actual message attribute.
string GenEnum(string Name) {
    bool needsComma = false;
    string code = "enum " ~ Name ~ " {";
    foreach( ele; __traits(allMembers, client.messages))
    {
        alias eleMen = hack!(__traits(getMember, client.messages, ele));

        static if ( is( eleMen : Message ) && !is( eleMen == Message) )
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

///Generate javascript code for the client so as to not hardcode opcodes both places, or generate endless stub RPC functions.
///This should be bound to a URL with the vibe-d router.
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


