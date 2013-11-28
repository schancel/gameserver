module channels.gochannel;

import std.uuid; //For giving the game a UUID

import channels.core;
import channels.chatchannel;
import messages;

import connections;
import sgf.gametree;
import sgf.parser;
import std.exception;

import std.algorithm;

const auto colorProperties = ["B", "W", "R", "G", "V"];

///Specialized channel for validating moves.
///Should support multi-color go.
class GoChannel : ChatChannel  //GoChannels are also chat channels.
{
    Connection[] players;
    int curPlayer = 0;
    int colors;
    GameNode head;
    GameNode curNode;

    this(string gamename)
    {
        super(gamename);
        colors = 2;
    }

    this(string gamename, Connection[] players, int colors = 2)
    {
        super(gamename);
        this.players = players;
        this.colors = min(colors, colorProperties.length);
    }

    override
    Message processMessage(Message m)
    {
        switch(m.opCode())
        {
            /*static*/ foreach(msgType; GetMessagesFromModules!("messages.game"))
            {
                case msgType.opCodeStatic:
                return m;
            }
            default:
                return super.processMessage(m); //Call ChatChannel's implementation.
        }
    }

    void pushSgfData(string sgfData)
    {
        if(head) {
            curNode = curNode.appendChild(new sgf.parser.SGFParser(sgfData).root);
        } else {
            head = new sgf.parser.SGFParser(sgfData).root;
            curNode = head;
        }
    }

    //Only allow the current player to play if they're adding the correct color.
    void playMove(Connection player, PlayMoveMessage move)
    {
        if(players[curPlayer] is player)
        {
            //TODO: Implement position checking for valid moves;
            curNode = curNode.appendChild();
            curNode.pushProperty( colorProperties[curPlayer % colors], move.position );
            curPlayer = (curPlayer++) % colors;
            send(move);
        }
    }
}