module channels.core;

import vibe.core.core;
import vibe.core.concurrency;
import vibe.core.log;

import std.stdio;
import std.string : toUpper;

import messages.core;
import connections;

import std.exception;

private __gshared Channel[string] channels;
private __gshared Object chanMutex = new Object();

///Get a channel of a particular type, if possible.  Possibly throws invalidcastexception.
Channel getChannel(string channelName)
{
    synchronized(chanMutex) 
    {
        if( auto p = channelName.toUpper() in channels )  
        {
            return (*p);
        } 
        else
        {
            import channels.chatchannel;
            //Channel adds itself to the list of channels
            //Default to a ChatChannel if not found.
            return new ChatChannel( channelName.toUpper() );
        }
    } 
}

///Subscribe to a channel of a particular type.  
void subscribeToChannel(Connection ci, string channelName)
{
    Channel chan = getChannel(channelName);
    chan.subscribe(ci);
}

///Unsubscribe from a channel by name.   Any type of channel will work, since we're not instantiating the channel if it doesn't exist.
void unsubscribeToChannel(Connection conn, string channelName)
{
    if( auto chan = channelName.toUpper() in channels )  
    {
        (*chan).unsubscribe(conn);
    }
}

///Send a message to a channel by name.
void sendToChannel( string channelName, Message m)
{
    synchronized(chanMutex){
        if( Channel* p = channelName.toUpper() in channels )  {
            (*p).send(m);
        } else {
            enforce(false, "Invalid channel" ~ channelName);
        }
    }
}

///Abstract channel class.  Other types of channels should derive from this.
abstract class Channel
{
    string name;
    private bool active;  //Tell our observer to stop.
    
    private Task observer; //Observes the channel and forwards messages to clients.
    bool[Connection] subscriptions;

    package this()
    {
    }

    protected this(string p_name)
    {
        active = true;
        name = p_name;
        
        synchronized(chanMutex)
        {
            channels[name] = this;
        }
        
        observer = runTask(&observerFunction);
    }

    final private void observerFunction()
    {
        try {
            while(active) {
                receive((shared Message m) {
                    if(active)
                    {
                        foreach( subscriber; subscriptions.byKey())
                        {
                            subscriber.send(processMessage(cast(Message)m));
                        }
                    }
                });
            }
        } catch ( InterruptException e)
        {
            //Shutdown.
        }
    }

    ///Called when the channel receives a message.   Processes the message and possibly morphs it into something else.
    ///Subtypes should override this if they want to handle certain messages in a special way.
    Message processMessage(Message m)
    {
        return m;
    }
    
    ~this()
    {
        active = false;
    }
    
    void send(Message m)
    {
        observer.send(cast(shared)m);
    }
    
    void subscribe(Connection conn) {
        subscriptions[conn] = true;
        conn.subscribe(this);
    }
    
    void unsubscribe(Connection conn) {
        subscriptions.remove(conn);
        conn.unsubscribe(this);
        if( subscriptions.length == 0)
        {
            logDebug("Disposing %s", name);
            channels.remove(name);
            active = false;
            observer.interrupt();
        }
    }
}