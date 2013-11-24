module channels.core;

import vibe.core.core;
import vibe.core.concurrency;

import std.stdio;
import std.string : toUpper;

import messages.core;
import client.connection;

import std.exception;

private __gshared Channel[string] channels;
private __gshared Object chanMutex = new Object();

static Channel getChannel(string channelName)
{
    synchronized(chanMutex) 
    {
        if( auto p = channelName.toUpper() in channels )  
        {
            return (*p);
        } 
        else
        {
            return new Channel(channelName.toUpper() ); //Channel adds itself to the list of channels.
        }
    } 
}

class Channel
{
    string name;
    private bool active;  //Tell our observer to stop.
    
    private Task observer; //Observes the channel and forwards messages to clients.
    bool[ConnectionInfo] subscriptions;

    protected this(string p_name)
    {
        active = true;
        name = p_name;

        synchronized(chanMutex)
        {
            channels[name] = this;
        }

        observer = runTask({
            while(active) {
                receive((shared Message m) {
                    if(active)
                        foreach( subscriber; subscriptions.byKey())
                    {
                        subscriber.send(cast(Message)m);
                    }
                });
            }
        });
    }

    ~this()
    {
        observer.terminate();
        active = false;
    }

    void send(Message m)
    {
        observer.send(cast(shared)m);
    }

    void subscribe(ConnectionInfo conn) {
        subscriptions[conn] = 0;
    };

    void unsubscribe(ConnectionInfo conn) {
        subscriptions.remove(conn);
        if( subscriptions.length == 0)
        {
            debug writefln("Disposing %s", name);
            channels.remove(name);
            destroy(this);
        }
    };
}

void subscribeToChannel(ConnectionInfo ci, string channelName)
{
    Channel chan = getChannel(channelName);
    chan.subscribe(ci);
    ci.subscribe(chan);
}

void unsubscribeToChannel(ConnectionInfo conn, string channelName)
{
    Channel chan = getChannel(channelName);

    chan.unsubscribe(conn);
    conn.unsubscribe(chan);
}

class NonExistantChannel : Exception {
    this(string channel)
    {
        super("Non existant channel: " ~ channel);
    }
}

void sendToChannel( string channelName, Message m)
{
    synchronized(chanMutex){
        if( Channel* p = channelName.toUpper() in channels )  {
            (*p).send(m);
        } else {
            throw new NonExistantChannel(channelName);
        }
    }
}