module messages.channel;

import std.typetuple;
import std.stdio;
import std.conv;

import vibe.core.stream;

import user.userinfo;

import channels;
import client.connection;

import messages.core;


@OpCoder(40)
class JoinMessage : Message
{
    string channel;
    string who;

    this() pure {}

    this(string channel, string who = null) pure 
    {
        this.channel = channel;
        this.who = who;
    }

    override void handleMessage(ConnectionInfo ci)
    {
        who = ci.user.Username; //Overwrite whatever nonsense the client might have sent with the correct name.

        debug writefln("%s: Joined channel %s", who, channel);
        subscribeToChannel!(ChatChannel)( ci, channel );
        sendToChannel(channel, this);
    }
    
    mixin messages.MessageMixin!("channel", "who");
}

@OpCoder(41)
class PartMessage : Message
{
    string channel;
    string who;

    this() pure {}

    this(string channel, string who = null) pure 
    {
        this.channel = channel;
        this.who = who;
    }
    
    override void handleMessage(ConnectionInfo ci)
    {
        who = ci.user.Username; //Overwrite whatever nonsense the client might have sent with the correct name.
        
        debug writefln("%s: Parted channel %s", who, channel);
        sendToChannel(channel, this);
        unsubscribeToChannel( ci, channel );
    }
    
    mixin messages.MessageMixin!("channel", "who");
}

@OpCoder(45)
class WhoMessage : Message
{
    string channel;

    this() pure {}

    this(string channel) pure 
    {
        this.channel = channel;
    }

    override void handleMessage(ConnectionInfo ci)
    {
        debug writefln("%s: Requested users of channel %s", ci.user.Username, channel);
        new WhoListMessage(channel).handleMessage(ci);
    }

    mixin messages.MessageMixin!("channel");
}

@OpCoder(46)
class WhoListMessage : Message
{
    string[] whoList;
    string channel;
    
    this() pure {}
    
    this(string channel) pure 
    {
        this.channel = channel;
    }

    override void handleMessage(ConnectionInfo ci)
    {
        foreach(curCi; getChannel!(ChatChannel)(channel).subscriptions.byKey())
            whoList ~= curCi.user.Username;

        ci.send(this);
    }

    override bool supportsIGS() { return true; };

    /***  Output should look like this for other clients to parse it.
     27  Info       Name       Idle   Rank |  Info       Name       Idle   Rank
     27  QX --   -- isfadm02   27s     2k  |   X --   -- zz0008      1m     NR 
     27   X256   -- guest4389   3m     NR  |   X --   -- AutoDone   35s     2k 
     27  QX --   -- livegw8     0s     NR  |  QX --   -- livegw7    58s     NR 
     27  QX --   -- livegw9     1m     NR  |  QX --   -- livegw10   56s     NR 
     27  QX --   -- livegw13   36s     NR  |  SX --   -- zz0004      3s     NR 
     27  QX --   -- livegw6     5s     NR  |  QX --   -- livegw5     5s     NR 
     27  QX --   -- livegw12   44s     NR  |  QX --   -- livegw11    1m     NR 
     27  Q  --   -- guest6427   3m     NR  |  QX --   -- haras      48s     3k*
     27  Q  --   -- guest9823   1m     NR  |  Q  --   -- guest7670   3s     NR 
     27  QX --   -- livegw4    31s     NR  |   X --   -- crocblanc   1m     7k*
     */

    override void writeIGS(OutputStream st)
    {
        int line = 0;
        st.put("27  Info       Name       Idle   Rank |  Info       Name       Idle   Rank");
        foreach(i, who; whoList)
        {
            if( i % 2 == 1)
                st.put("  |");
            else 
                st.put("\r\n27 ");
            st.put("    --   -- " ~ who ~ "    0s     NR");
        }
        st.flush();
    }
    
    mixin messages.MessageMixin!("channel", "whoList");
}