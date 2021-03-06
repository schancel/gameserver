module channels.gochannel;


import vibe.core.log;

import std.stdio;
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

struct PlayerInfo
{
    Connection conn;
    bool ready;
}

///Specialized channel for validating moves.
///Should support multi-color go.
///
///TODO: Synchronize movement and loading sgfs.
class GoChannel : ChatChannel  //GoChannels are also chat channels.
{
    static shared uint gameIDCounter = 0;
    immutable int gameID;

    PlayerInfo[] players;
    Connection owner;
    int curPlayer = 0;
    StoneColor curColor = StoneColor.BLACK; //Maintain colors separately so the colors cycle when not enough players.
    int colors;

    private GameNode head;
    private GameNode curNode;
    private Goban board;

    bool started;
    bool freeGame;

    @property const(GameNode) sgfData() const
    {
        return head;
    }
    @property const(Goban) rawBoard() const
    {
        return board;
    }

    package this()
    {
        gameID = core.atomic.atomicOp!"+="(gameIDCounter, 1);
        super(randomUUID().toString);

        registerGame(this);

        colors = 2;
    }

    private this(string gameName)
    {
        enforce(false, "Cannot call with a gamename!  It is autogenerated.");
        this();
    }

    ~this()
    {
        logDebug("Unregistering game!");
        unregisterGame(this);
    }
   

    this(Connection owner, int colors = 2)
    {
        this();
        this.owner = owner;

        board = new GobanImpl!(AGARules);
        players ~= PlayerInfo(owner, false);

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
            curNode.appendChild(new sgf.parser.SGFParser(sgfData).root);
        } else {
            head = new sgf.parser.SGFParser(sgfData).root;
            curNode = head;
        }
    }

    //Load a next child, and the appropriate board positions.
    void gotoChild(int child)
    {
        //TODO: make this method more robust.
        enforce(child >= 0 && child < curNode.Children.length, "Invalid SGF Path sent.");
        curNode = curNode.Children[child];

        foreach(prop; curNode.Properties.byKey().filter!((k) => colorProperties.countUntil(k) != -1))
        {
            foreach(val; curNode.Properties[prop])
            {
                board.playStone(Position(val), getStoneColor(prop));
            }
        }

        foreach(prop; curNode.Properties.byKey().filter!((k) => ["AW", "AB"].countUntil(k) != -1))
        {
            foreach(val; curNode.Properties[prop])
            {
                board[Position(val)] = getStoneColor(prop[1..$]);
            }
        }
    }

    //TODO: send an appropiate message to all clients to navigate in their sgfs.
    void gotoPath(int[] path)
    {
        curNode = head;
        board = new GobanImpl!(AGARules); //reset board


        foreach(child; path)
        {
            gotoChild(child);
        }
    }

    //Only allow the current player to play if they're adding the correct color.
    void playMove(Connection player, PlayMoveMessage move)
    {
        enforce(started, "Game not started!");

        if(player == players[curPlayer].conn && move.position)
        {
            Position pos = Position(move.position);

            if( board.playStone(pos, curColor) )
            {
                curNode = curNode.appendChild();
                curNode.pushProperty( curColor.getColorString(), move.position );

                //Cycle through players
                curPlayer = (curPlayer++) % cast(int)players.length;

                //Cycle through colors.
                ++curColor;
                if(curColor > colors)
                {
                    curColor = StoneColor.BLACK;
                }

                send(move);
            } else {
                enforce(false, "Invalid move");
            }
        } else {
            enforce(false, "Invalid move");
        }
    }

    public void undo()
    {
        curNode = curNode.Parent; //Backup
        board.revert(); //Undo one.
    }

    void readyPlayer(Connection player)
    {
        foreach( ref p; players.filter!(curPlayer => curPlayer.conn == player))
            p.ready = true;
    }

    void setPlayerPosition(string player, size_t pos)
    {
        enforce( pos >= 0 && pos <= players.length, "Invalid player position!");

        players[pos..pos+1].swapRanges(players.filter!(a => a.conn.userinfo.Username.toUpper == player.toUpper));
    }

    void addPlayer(string playerName)
    {
        if(!started) {
            foreach(conn; subscriptions.byKey.filter!(conn=> conn.userinfo.Username.toUpper == playerName.toUpper)) {
                players ~= PlayerInfo(conn, false);
            }
        }
    }

    ///Use this if somebody changes a setting.  Should unready all players.
    void removePlayer(string playerName)
    {
        if(started) return;

        players = players.remove!(a => a.conn.userinfo.Username.toUpper == playerName.toUpper);
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
        enforce( players.length > 0, "Cannot start game. No players!");

        bool allready = true;
        foreach(plyrInfo; players) {
            allready &= plyrInfo.ready;
        }

        started = allready;
        head = new GameNode();
        curNode = head;
    }
}