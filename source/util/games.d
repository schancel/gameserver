module util.games;

import channels.gochannel;
import std.exception :enforce;

private __gshared GoChannel[int] gamesByID;
private __gshared GoChannel[string] games;

private __gshared Object gameMutex = new Object();

///Get a channel of a particular type, if possible.  Possibly throws invalidcastexception.
GoChannel getGameByID(int id)
{
    synchronized(gameMutex) 
    {
        if( auto p = id in gamesByID ) {
            return *p;
        }  else {
            enforce(false, "No such game.");
        }
    }

    assert(0, "Shouldn't be here");
}

GoChannel getGame(string game)
{
    synchronized(gameMutex) 
    {
        if( auto p = game in games ) {
            return *p;
        }  else {
            enforce(false, "No such game.");
        }
    }
    assert(0, "Shouldn't be here");
}

void registerGame(GoChannel chan)
{
    synchronized(gameMutex) 
    {
        enforce(chan.gameID !in gamesByID, "Game already exists?  How is this possible?");
        enforce(chan.name !in games, "Game already exists?  How is this possible?");

        gamesByID[chan.gameID] = chan;
        games[chan.name] = chan;
    }
}

void unregisterGame(GoChannel chan)
{
    synchronized(gameMutex) 
    {
        if( auto p = chan.gameID in gamesByID ) {
            gamesByID.remove(chan.gameID);
        } else {
            enforce(false, "No such game.");
        }

        if( auto p = chan.name in games ) {
            games.remove(chan.name);
        } else {
            enforce(false, "No such game.");
        }
    }
}