module client.connection;

import std.container;
import std.stdio;
import core.time;
import std.conv;
import std.array : join;

import vibe.core.core;
import vibe.core.driver;
import vibe.http.server;
import vibe.http.websockets;
import vibe.stream.ssl;
import vibe.core.concurrency;
import vibe.core.log;
import vibe.stream.operations;

import client.messages;
import gameserver.channels;
import user.userinfo;

class ConnectionInfo
{ 
    protected Task writeTask, readTask;
    bool active;
    UserInfo user;
    bool[Channel] subscriptions;
    ulong curThread;

    this()
    {
        active = true;
    }

    ~this()
    {
        debug writefln("%d: disconnected", curThread);
        foreach( sub; subscriptions.byKey() )
        {
            sub.unsubscribe(this);
        }
    }

    void broadcast( Message m )
    {
        foreach( chan; subscriptions.byKey() )
            chan.send(m);
    }

    void send( Message m )
    {
        writeTask.send(cast(shared)m);
    }

    void subscribe(Channel chan) {
        synchronized (this)
        {
            subscriptions[chan] = true;
        }
    };

    void unsubscribe(Channel chan) {
        synchronized (this)
        {
            subscriptions.remove(chan);
        }
    };
}