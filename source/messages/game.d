module messages.game;

import connections;

import std.typetuple;
import std.stdio;
import std.conv;

import vibe.core.stream;

import user.userinfo;
import channels;

import messages.core;

shared uint gameID = 0;

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
        this.game = game;
        this.sgfData = sgfData;
    }

    override void handleMessage(Connection ci)
    {
        gameID++;
        this.game = gameID.to!string; 

        auto gogame = new GoChannel(game, [ci], colors);
        gogame.pushSgfData(sgfData);

        subscribeToChannel!(GoChannel)(ci, game);
    }
    
    mixin messages.MessageMixin!("sgfData");
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
        auto gogame = getChannel!(GoChannel)(game);

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


@OpCoder(120)
class InvalidMoveMessage : Message
{
    string game;

    this() pure {}

    this(string game)
    {
        this.game = game;
    }

    mixin messages.MessageMixin!("game");
}

