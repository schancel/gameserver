module gameserver.channels;

import vibe.core.core;
import vibe.core.concurrency;

import std.container;
import std.stdio;
import core.time;
import std.conv;

import client.messages;
import client.connection;

alias Message = client.messages.Message;

class Channel
{
    static Channel[string] channels;

    string name;
    private bool active;
    
    private Task observer; //Observes the channel and forwards messages to clients.
    bool[ConnectionInfo] subscriptions;

    static Channel getChannel(string channelName)
    {
        if( auto p = channelName in Channel.channels )  
        {
            return (*p);
        } 
        else
        {
            return new Channel(channelName);
        }
    }
    
    this(string p_name)
    {
        active = true;
        name = p_name;
        channels[name] = this;
        observer = runTask({
            while(active) {
                receive((shared Message m) {
                    if(active)
                        foreach( subscriber; subscriptions.byKey())
                        {
                            subscriber.send(m);
                        }
                });
            }
        });
    }

    ~this()
    {
        active = false;
    }

    void send(shared Message m)
    {
        observer.send(m);
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

void subscribeToChannel(ConnectionInfo conn, string channelName)
{
    Channel chan = Channel.getChannel(channelName);

    chan.send(new shared JoinMessage());
    chan.subscribe(conn);
    conn.subscribe(chan);
}

void unsubscribeToChannel(ConnectionInfo conn, string channelName)
{
    Channel chan = Channel.getChannel(channelName);
    
    chan.unsubscribe(conn);
    conn.unsubscribe(chan);
}


void sendToChannel( string channelName, shared Message m)
{
    if( Channel* p = channelName in Channel.channels )  {
        (*p).send(m);
    }
}