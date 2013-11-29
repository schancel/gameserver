module messages.user;

import std.typetuple;
import std.stdio;
import std.conv;

import vibe.core.stream;
import vibe.core.log;

import user.userinfo;

import channels;
import connections;

import messages.core;

///Request user info, and get it back.
@OpCoder(20)
class UserInfoMessage : Message
{
    string username;
    int rating;

    this()
    {
        // Constructor code
    }

    //TODO: Handle this message.

    mixin MessageMixin!("username", "rating");
}

