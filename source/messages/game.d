module messages.game;

import client.connection;

import std.typetuple;
import std.stdio;
import std.conv;

import vibe.core.stream;

import user.userinfo;
import channels;

import messages.core;

shared uint gameID = 0;

@OpCoder(100)
class NewGame : Message
{
    string game;
    string sgfData;

    this()
    {
        gameID++;
        this.game = gameID.to!string; 
    }
    
    this(string game, string sgfData)
    {
        this.game = game;
        this.sgfData = sgfData;
    }
    
    mixin messages.MessageMixin!("sgfData");
}

///Send this message to initiate a close of the connection.
@OpCoder(110)
class PlayMoveMessage : Message
{
    string game;
    string sgfData;

    this() pure {}

    this(string game, string sgfData)
    {
        this.game = game;
        this.sgfData = sgfData;
    }

    mixin messages.MessageMixin!("game", "sgfData");
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

