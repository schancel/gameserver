module client.messages;

import user.userinfo;

enum OpCode
{
    None = 0,
    Join = 1,
    ChatMessage = 2,
    Shutdown = 3
}

class Message
{
    shared {
        int opCode;
        string message;

        this(string msg)
        {
            opCode = OpCode.None;
            message = msg;
        }

        this() { }

        string toString() const
        {
            return message;
        }
    }

    override string toString() const
    {
        return message;
    }
}

shared class JoinMessage : Message
{
    this()
    {
        opCode = OpCode.Join;
        message = "Joined!";
    }
}

shared class ChatMessage : Message
{
    UserInfo user;
    string channel;

    this(shared UserInfo user, string channel, string msg ) 
    {
        opCode = OpCode.ChatMessage;
        this.user = user;
        this.message = msg;
        this.channel = channel;
    }
}

shared class ShutdownMessage : Message
{
    this()
    {
        opCode = OpCode.Shutdown;
    }
}