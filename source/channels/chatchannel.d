module channels.chatchannel;

import vibe.core.core;
import vibe.core.concurrency;

import std.stdio;
import std.string : toUpper;

import messages.core;
import channels.core;
import client.connection;

import std.exception;

class ChatChannel : Channel
{
    this(string channelName)
    {
        super(channelName);
    }

    override
    Message processMessage(Message m)
    {
        switch(m.opCode())
        {
            /*static*/ foreach(msgType; GetMessagesFromModules!("messages.chat", "messages.channel"))
            {
                case msgType.opCodeStatic:     
                return m;
            }
            default:
                throw new InvalidChannelMessageException(this, m);
        }
    }
}