module user.core;

import std.exception;
import connections;
import user.userinfo;
import messages.core;
import std.string;

private __gshared  Connection[string] userConnections;
private __gshared Object connMutex = new Object();

Connection getUser(string username)
{
    synchronized(connMutex)
    {
        if( auto user = username.toUpper() in userConnections )
        {
            return (*user);
        } else {
            return null;
        }
    }
}

void registerUser(string username, Connection ci)
{
    synchronized(connMutex)
    {
        if( auto conn = username.toUpper() in userConnections )
        {
            (*conn) = ((*conn).add(ci));
        } else {
            userConnections[username.toUpper()] = ci;
        }
    }
}

void unregisterUser(string username, Connection ci)
{
    synchronized(connMutex)
    {

        if( auto user = username.toUpper() in userConnections )
        {
            auto res = (*user).remove(ci);
            if( res is null )
            {
                userConnections.remove(username.toUpper());
            }
        }
    }
}

void sendToUser(string username, Message msg)
{
    auto user  = getUser(username);
    enforce(user, "Invalid user target");

    user.send(msg);
}
