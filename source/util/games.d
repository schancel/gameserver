module util.igs;

import channels.gochannel;

private __gshared GoChannel[int] games;
private __gshared Object gameMutex = new Object();

///Get a channel of a particular type, if possible.  Possibly throws invalidcastexception.
GoChannel getGameByID(int id)
{
    synchronized(gameMutex) 
    {
        if( auto p = channelName.toUpper() in channels ) {
            return *p;
        }  else {
            enforce(false, "No such game.");
        }
    }
}

void registerGame(GoChannel chan, int id)
{
    synchronized(chanMutex) 
    {
        enforce(id !in channels, "Game already exists?  How is this possible?");
        games[id] = chan;
    }
}

void unregisterGame(GoChannel chan, int id)
{
    synchronized(chanMutex) 
    {
        if( auto p = id in channels ) {
            games.remove(id);
        } else {
            enforce(false, "No such game.");
        }
    }
}