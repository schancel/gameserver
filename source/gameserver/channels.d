module gameserver.channels;

import vibe.core.core;
import vibe.core.concurrency;

import std.container;
import std.stdio;
import core.time;
import std.conv;
import std.string : toUpper;

import client.messages;
import client.connection;

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
            return new Channel(channelName); //Channel adds itself to the list of channels.
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
                            subscriber.send(cast(Message)m);
                        }
                });
            }
        });
    }

    ~this()
    {
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
    Channel chan = Channel.getChannel(channelName.toUpper());

    chan.subscribe(ci);
    ci.subscribe(chan);
    chan.send(new JoinedMessage(channelName, ci.user.Username));
}

void unsubscribeToChannel(ConnectionInfo conn, string channelName)
{
    Channel chan = Channel.getChannel(channelName.toUpper());

    chan.unsubscribe(conn);
    conn.unsubscribe(chan);
}

void sendToChannel( string channelName, Message m)
{
    if( Channel* p = channelName.toUpper() in Channel.channels )  {
        (*p).send(m);
    }
}