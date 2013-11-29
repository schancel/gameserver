module connections.core;

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

import messages;
import channels;
import user.userinfo;
import user.core;

import connections.connectionset;

abstract class Connection
{
    void broadcast( Message m ) {assert(0, "Not implemented");}
    void send( Message m ) {assert(0, "Not implemented");}
    void subscribe(Channel chan) {assert(0, "Not implemented");}
    void unsubscribe(Channel chan) {assert(0, "Not implemented");}
    @property UserInfo userinfo() {assert(0, "Not implemented");}
    @property void userinfo(UserInfo) {assert(0, "Not implemented");}

    Connection add(Connection rhs) {assert(0, "Not implemented");}
    Connection remove(Connection rhs) {assert(0, "Not implemented");}
}

class ConnectionBase : Connection
{ 
    protected{
        protected Task writeTask, readTask;
        bool active;
        UserInfo user;
        bool[Channel] subscriptions;
        ulong curThread;
        bool[string] prefs;
    }

    this()
    {
        active = true;
    }

    ~this()
    {
        logDebug("%d: disconnected", curThread);
        foreach( sub; subscriptions.byKey() )
        {
            sub.unsubscribe(this);
        }
        userinfo = null;
    }

    override void broadcast( Message m )
    {
        foreach( chan; subscriptions.byKey() )
            chan.send(m);
    }

    override void send( Message m )
    {
        writeTask.send(cast(shared)m);
    }

    override void subscribe(Channel chan)
    {
        synchronized (this)
        {
            subscriptions[chan] = true;
        }
    }

    override void unsubscribe(Channel chan)
    {
        synchronized (this)
        {
            subscriptions.remove(chan);
        }
    }

    override @property UserInfo userinfo()
    {
        return this.user;
    }

    override @property void userinfo(UserInfo ui)
    {
        if( !user || !ui || ui.Username != user.Username )
        {
            if( user ) unregisterUser(this.user.Username, this);
            if( ui ) registerUser(ui.Username, this);
        }
        this.user = ui;
    }

    override
    Connection add(Connection rhs)
    {
        auto cset = new ConnectionSet();

        cset.add(this);
        cset.add(rhs);

        return cset;
    }

    override Connection remove(Connection rhs)
    {
        return null;
    }
}