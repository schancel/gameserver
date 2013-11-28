module messages.auth;

import connections;

import std.typetuple;
import std.stdio;
import std.conv;

import vibe.core.stream;

import user;
import channels;

import messages.core;

///Send this message to initiate a close of the connection.
///
@OpCoder(1)
class ShutdownMessage : Message
{
    this() pure {}

    mixin messages.MessageMixin!();
}

///Handles allowing user to authenticate.  They are a guest until they do this.
@OpCoder(5)
class AuthMessage : Message
{
    string username;
    string password;
    
    this() pure {}
    
    this(string username, string password = "") pure 
    {
        this.username = username;
        this.password = password;
    }
    
    override void handleMessage(Connection ci)
    {
        auto oldName = ci.userinfo.Username; //Overwrite whatever nonsense the client might have sent with the correct name.
        ci.userinfo = new UserInfo(username);

        debug writefln("%s: Authenticated as %s", oldName, ci.userinfo.Username);

        ci.send(new AuthResponseMessage(ci.userinfo.Username));
    }
    
    mixin messages.MessageMixin!("username", "password");
}


///Responds to the authentication message with their new authenticated username.
///May not be what was requested in the case of an authentication failure.
@OpCoder(6)
class AuthResponseMessage : Message
{
    string username;

    this() pure {}

    this(string username) pure
    {
        this.username = username;
    }

    mixin messages.MessageMixin!("username");
}
