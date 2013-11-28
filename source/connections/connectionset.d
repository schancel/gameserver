module connections.connectionset;

import connections.core;
import messages;
import channels;
import user;

//Wraps a set of connections together.   Allows people to be connected multiple times.
class ConnectionSet : Connection
{
    bool[Connection] connections;

    this()
    {
    }

    override
    Connection add(Connection rhs) 
    {
        if( rhs !in connections)
            connections[rhs] = true;

        return this;
    }

    override Connection remove(Connection rhs)
    {
        if( rhs in connections)
        {
            connections.remove(rhs);

            if( connections.length == 0 )
            {
                return null; //We shouldn't exist anymore.
            }
        }

        return this;
    }

    override void broadcast( Message m )
    {
        enforce(0, "Cannot broadcast through a connection set.  Check your code");
    }

    override void send( Message m )
    {
        foreach( conn; connections.byKey())
        {
            conn.send(m);
        }
    }

    override void subscribe(Channel chan)
    {
        enforce(0, "Cannot subscribe through a connection set.  Check your code");
    }

    override void unsubscribe(Channel chan)
    {
        enforce(0, "Cannot unsubscribe through a connection set.  Check your code");
    }

    override @property UserInfo userinfo()
    {
        if( connections.length > 0 )
        {
            foreach(ci; connections.byKey())
                return ci.userinfo(); //Return first userinfo.  They *should* be the same.
        }

        assert(0, "Error, invalid ConnectionSet");
    }
}

