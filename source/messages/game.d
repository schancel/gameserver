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

///Send this message to challenge a user.
@OpCoder(99)
class ChallengeMessage : Message
{
    string challenger;
    string challengee;
    int time; //Total time in minutes.
    int byotime; //Time to play 25 moves.
    
    this()
    {
    }

    override void handleMessage(Connection ci)
    {
    }
    
    mixin messages.MessageMixin!("challenger", "challengee");
}


///Send this message to start a new game.
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
    
    mixin messages.MessageMixin!("game", "sgfData", "colors");
}

///Add a player to the game from the list of observers if the game hasn't started.
@OpCoder(101)
class AddPlayerMessage : Message
{
    string game;
    string player;
    
    override void handleMessage(Connection ci)
    {   
        auto gogame = getGame(game);

        gogame.addPlayer(player);
    }
    
    mixin messages.MessageMixin!("game", "player");
}

///User is ready to play game.
@OpCoder(102)
class RemovePlayerMessage : Message
{
    string game;
    string player;

    override void handleMessage(Connection ci)
    {   
        auto gogame = getGame(game);

        gogame.removePlayer(player);
    }
    
    mixin messages.MessageMixin!("game", "player");
}

///User is ready to play game.
@OpCoder(103)
class ReadyMessage : Message
{
    string game;
    string player;

    override void handleMessage(Connection ci)
    {   
        auto gogame = getGame(game);

        gogame.readyPlayer(ci);
    }

    mixin messages.MessageMixin!("game", "player");
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

    override bool supportsIGS() { return true; }

    override void writeIGS(OutputStream st)
    {
        //TODO:  Output something like this:
        //MOVE Game <GameNumber> I: <WhitePlayer> (? time? ?) vs <BlackPlayer> (<captures> time? ?)
        //15 Game 87 I: eluusive (0 4299 -1) vs mewph (4 4104 -1)

        //MOVE <MOVE#>(<COLOR>): <MOVELOCATION>
        //15  12(B): E4
    }

    mixin messages.MessageMixin!("game", "position");
}


///Send this message to play a pass.
@OpCoder(111)
class PassMessage : Message
{
    string game;
    string player;

    this() pure {}
    
    this(string game, string player)
    {
        this.game = game;
        this.player = player;
    }
    
    override void handleMessage(Connection ci)
    {
    }
    
    override bool supportsIGS() { return true; }
    
    override void writeIGS(OutputStream st)
    {
        //TODO:  Output something like this:
        //MOVE Game <GameNumber> I: <WhitePlayer> (? time? ?) vs <BlackPlayer> (<captures> time? ?)
        //15 Game 87 I: eluusive (0 4299 -1) vs mewph (4 4104 -1)
        
        //MOVE <MOVE#>(<COLOR>): <MOVELOCATION>
        //15  12(B): E4
    }
    
    mixin messages.MessageMixin!("game");
}

///Send this to resign the game.
@OpCoder(112)
class ResignMessage : Message
{
    string game;
    string player;

    this() pure {}

    this(string game, string player)
    {
        this.game = game;
        this.player = player;
    }
    
    override void handleMessage(Connection ci)
    {
    }
    
    override bool supportsIGS() { return true; }
    
    override void writeIGS(OutputStream st)
    {
        //INFO <user> has resigned the game.

    }
    
    mixin messages.MessageMixin!("game", "player");
}

///Send this to resign the game.
@OpCoder(113)
class ToggleDeadMessage : Message
{
    string game;
    string position;
    bool dead;
    
    this() pure {}
    
    this(string game, string position)
    {
        this.game = game;
        this.position = position;
    }
    
    override void handleMessage(Connection ci)
    {
    }
    
    override bool supportsIGS() { return false; }
    
    override void writeIGS(OutputStream st)
    {
    }
    
    mixin messages.MessageMixin!("game", "position", "dead");
}

///Send the path of the move to navigate to in the SGF.
///Broadcasts to all users.
@OpCoder(120)
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




