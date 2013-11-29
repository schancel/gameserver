module messages.auth;

import connections;

import std.typetuple;
import std.stdio;
import std.conv;

import vibe.core.stream;
import vibe.core.log;

import user;
import channels;

import messages.core;
import util.mysql;

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
        writeln("What2");

        auto oldName = ci.userinfo ? ci.userinfo.Username : "(null)"; //Overwrite whatever nonsense the client might have sent with the correct name.

        writeln("Hrm");
        if( Database.AuthUser(username, password) )
        {
            ci.userinfo = new UserInfo(username);
            logDebug("%s: Authenticated as %s", oldName, ci.userinfo.Username);
        } else {
            ci.userinfo = new UserInfo("AnonymousCoward");
        }

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
