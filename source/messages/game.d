module messages.game;

import connections;

import std.typetuple;
import std.stdio;
import std.conv;

import vibe.core.stream;

import user.userinfo;
import channels;
import util.games;

import messages.core;

@OpCoder(100)
class NewGameMessage : Message
{
    string game;
    string sgfData;
    int colors = 2;

    this()
    {
    }
    
    this(string game, string sgfData)
    {
        this.sgfData = sgfData;
    }

    override void handleMessage(Connection ci)
    {
        auto gogame = new GoChannel(ci, colors);

        game = gogame.name;
        gogame.pushSgfData(sgfData);

        gogame.subscribe(ci);
        ci.subscribe(gogame);
    }
    
    mixin messages.MessageMixin!("sgfData");
}

///User is ready to play game.
@OpCoder(101)
class AddPlayerMessage : Message
{
    string game;
    
    override void handleMessage(Connection ci)
    {   
        auto gogame = getGame(game);
    }
    
    mixin messages.MessageMixin!("game");
}

///User is ready to play game.
@OpCoder(102)
class RemovePlayerMessage : Message
{
    string game;
    
    override void handleMessage(Connection ci)
    {   
        auto gogame = getGame(game);
    }
    
    mixin messages.MessageMixin!("game");
}

///User is ready to play game.
@OpCoder(103)
class ReadyMessage : Message
{
    string game;

    override void handleMessage(Connection ci)
    {   
        auto gogame = getGame(game);

        gogame.readyPlayer(ci);
    }

    mixin messages.MessageMixin!("game");
}


///Send this message to initiate a close of the connection.
@OpCoder(110)
class PlayMoveMessage : Message
{
    string game;
    string position;

    this() pure {}

    this(string game, string position)
    {
        this.game = game;
        this.position = position;
    }

    override void handleMessage(Connection ci)
    {
        auto gogame = getGame(game);

        gogame.playMove(ci, this);
    }

    mixin messages.MessageMixin!("game", "position");
}

@OpCoder(111)
class GotoMoveMessage : Message
{
    string game;
    int[] sgfPath;
    
    this() pure {}
    
    this(int[] sgfPath)
    {
        this.sgfPath = sgfPath;
    }
    
    mixin messages.MessageMixin!("game", "sgfPath");
}




