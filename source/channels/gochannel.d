module channels.gochannel;


import vibe.core.log;

import std.algorithm;
import std.uuid; //For giving the game a UUID

import channels.core;
import channels.chatchannel;
import messages;
import goban;
import util.games;

import connections;
import sgf.gametree;
import sgf.parser;
import std.exception;


const auto colorProperties = ["B", "W", "R", "G", "V"];

struct PlayerInfo
{
    Connection conn;
    StoneColor color;
    ulong playerNum;
    bool ready;
}

///Specialized channel for validating moves.
///Should support multi-color go.
class GoChannel : ChatChannel  //GoChannels are also chat channels.
{
    static shared uint gameIDCounter = 0;

    immutable string gameUUID;
    immutable int gameID;

    PlayerInfo[string] players;
    int curPlayer = 0;
    int colors;

    private GameNode head;
    private GameNode curNode;
    private Goban board;

    bool started;
    bool freeGame;

    package this()
    {
        gameID = ++gameIDCounter;
        gameUUID = randomUUID().toString;
        registerGame(this);

        super(gameUUID);
        colors = 2;
    }

    package this(string gameName)
    {
        enforce(false, "Cannot call with a gamename!");
        this();
    }

    ~this()
    {
        logDebug("Unregistering game!");
        unregisterGame(this);
    }

    this(Connection[] players, int colors = 2)
    {
        this();
        board = new GobanImpl!(AGARules);
        this.colors = colors;


        foreach(i, ci; players)
        {
            this.players[ci.userinfo.Username] = PlayerInfo(ci, StoneColor.EMPTY, i, false);
        }

        this.colors = min(colors, colorProperties.length);
    }

    override Message processMessage(Message m)
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
        auto plyrInfo = player.userinfo.Username in players;
        if(plyrInfo && (*plyrInfo).playerNum == curPlayer && move.position)
        {
            Position pos = Position(move.position);
            if( board.playStone(pos, cast(StoneColor)((curPlayer+1) % colors)) )
            {
                curNode = curNode.appendChild();
                curNode.pushProperty( colorProperties[curPlayer % colors], move.position );
                curPlayer = (curPlayer++) % colors;
                send(move);
            } else {
                enforce(false, "Invalid move");
            }
        } else {
            enforce(false, "Invalid move");
        }
    }

    void readyPlayer(Connection player)
    {
        if(auto plyrInfo = player.userinfo.Username in players)
        {
            (*plyrInfo).ready = true;
        }
    }

    void addPlayer(string username)
    {
        if(!started) {
            foreach(conn; subscriptions.byKey) {
                if( conn.userinfo.Username.toUpper == username.toUpper) {
                    players[conn.userinfo.Username] = PlayerInfo(conn, StoneColor.EMPTY, players.length, false);
                }
            }
        }
    }

    void setPlayerColor(string player, StoneColor color)
    {
        players[player].color = color;
    }

    void removePlayer(string username)
    {
        if(started) return;

        if(auto plyrInfo = username in players) {
            players.remove(username);
        }
    }

    void unreadyPlayers()
    {
        if(started) return;

        foreach(plyrInfo; players) {
            plyrInfo.ready = false;
        }
    }

    void startGame()
    {
        bool allready = true;
        foreach(plyrInfo; players) {
            allready &= plyrInfo.ready;
        }

        started = allready;
    }
}