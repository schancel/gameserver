module messages.error;

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

///Should not be sent by client.
@OpCoder(255)
class ErrorMessage : Message
{
    string message;
    
    this() pure {}
    
    this(string message)
    {
    }
    
    mixin messages.MessageMixin!("message");
}