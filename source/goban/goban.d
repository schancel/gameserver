module goban.goban;

import goban.rules;
import goban.position;
import goban.colors;
import std.container : Array;
import std.array : Appender;
import std.conv:to;
interface Goban
{
    void revert();
    void commit();
    StoneColor opIndexAssign(StoneColor color, Position pos);
    StoneColor opIndex(Position idx);
    bool playStone(Position pos, StoneColor color);

    bool compareBoard(BoardState);

    @property int size() const;

    void addCaptures(StoneColor, int captures);

    @property Array!(BoardState) previousStates();

    string toString() const;
}

struct BoardState
{
    StoneColor[] stones;
    int[] captures;

    this(uint size = 19)
    {
        stones = new StoneColor[size*size];
        captures = new int[StoneColor.max];
    }

    this( BoardState oldState )
    {
        stones = oldState.stones.dup;
        captures = oldState.captures.dup;
    }
}

class GobanImpl(rulesType : Rules) : Goban 
{
    private int _size;
    BoardState state;

    Array!(BoardState) undoStack;  //Stores an array of delegates so we can undo moves.
    Rules rules;

    /***
     * Create a new board.  Requires a board size.  Only square boards are supposed.
     */
    this(int size = 19)
        in
    {
        enforce(size < 36, "Invalid board size");
    }
    body {
        this._size = size;
        this.state = BoardState(size);
        this.rules = new rulesType(this);
    }

    /***
     * Revert to a previous state.
     */
    void revert() {
        if( ! undoStack.empty() )
        {
            auto undo = undoStack.back();
            state.captures = undo.captures;
            state.stones = undo.stones;
            undoStack.removeBack();
        }
    }

    @property int size() const
    {
        return _size;
    }

    @property Array!(BoardState) previousStates()
    {
        return undoStack;
    }

    void commit()
    {
        undoStack.insertBack(BoardState(state));
    }

    /*** 
     * Add a stone to the board.  Do not apply rules.
     */
    StoneColor opIndexAssign(StoneColor color, Position pos)
    {
        return state.stones[pos.x + pos.y*size] = color;
    }

    /*** 
     * Get the stone at a particular position.
     */
    StoneColor opIndex(Position pos)
    {
        return state.stones[pos.x + pos.y*size];
    }

    /***
     * Place a stone on the board, and apply rules.
     */
    bool playStone(Position pos, StoneColor color)
    {
        if( rules.check( pos, color))
        {
            this[pos] = color;
            rules.apply( pos, color); //Commits board at end.
            commit();

            return true;
        }

        return false;
    }

    bool compareBoard( BoardState rhs )
    {
        return state.stones == rhs.stones;
    }

    void addCaptures(StoneColor color, int captures)
    {
        state.captures[color] += captures;
    }

    override string toString() const
    {

        /+  TODO: Output something like this:
         + 
         + 
         +  15 Game 87 (I): eluusive [ 6k ] vs mewph [10k ]
         +  15       A B C D E F G H J K L M N O P Q R S T      H-cap 4 Komi -5.5
         +   15   19 |. . . . . . . . . . . . . . . . . . .| 19  Captured by #: 4
         +   15   18 |. . . . . . . . . . . . . . . . . . .| 18  Captured by O: 0
         +   15   17 |. . . . . . . . . . . . . . . . . . .| 17
         +   15   16 |. . . # . . . . . + . . . . . # . . .| 16  Wh Time 71:39 
         +   15   15 |. . . . . . . . . . . . . . . . . . .| 15  Bl Time 72:04 
         +   15   14 |. . . . . . . . . . . . . . . . . . .| 14
         +   15   13 |. . . . . . . . . . . . . . . . . . .| 13   Last Move: D3
         +   15   12 |. . . . . . . . . . . . . . . . . . .| 12    #12 O (White)
         +   15   11 |. . . . . . . . . . . . . . . . . . .| 11
         +   15   10 |. . . + . . . . . + . . . . . + . . .| 10     B # 11 D1
         +   15    9 |. . . . . . . . . . . . . . . . . . .|  9     W # 10 C1
         +   15    8 |. . . . . . . . . . . . . . . . . . .|  8     B #  9 C2
         +   15    7 |. . . . . . . . . . . . . . . . . . .|  7     W #  8 C3
         +   15    6 |. . . . . . . . . . . . . . . . . . .|  6     B #  7 B3
         +   15    5 |. . . . . . . . . . . . . . . . . . .|  5     W #  6 B2
         +   15    4 |. . . # . . . . . + . . . . . # . . .|  4     B #  5 A3
         +   15    3>|# # O>O<. . . . . . . . . . . . . . .|< 3     W #  4 B1
         +   15    2 |# . # . . . . . . . . . . . . . . . .|  2     B #  3 A2
         +   15    1 |. . . # . . . . . . . . . . . . . . .|  1     W #  2 A1
         +   9       A B C D E F G H J K L M N O P Q R S T +/

        Appender!string output;

        foreach( i, stone; state.stones )
        {
            if( i%size == 0 && i != 0)
            {
                output.put("\n");
            }
            switch(stone)
            {
                case StoneColor.EMPTY:
                    output.put(" .");
                    break;
                case StoneColor.WHITE:
                    output.put(" O");
                    break;
                case StoneColor.BLACK:
                    output.put(" #");
                    break;
                default:
                    output.put(to!string(cast(int)stone));
                    break;
            }
        }

        return output.data;
    }
}

unittest
{
    import std.stdio;
    auto board = new GobanImpl!(AGARules)();

    //Check suicide
    board.playStone(Position(1,0), StoneColor.WHITE);
    assert(board[Position(1,0)] == StoneColor.WHITE, "Didn't get back same stone color!");
    board.playStone(Position(0,1), StoneColor.WHITE);
    assert(board.playStone(Position(0,0), StoneColor.BLACK) == false, "Allowed black to suicide");

    board.playStone(Position(2,0), StoneColor.BLACK);
    board.playStone(Position(1,1), StoneColor.BLACK);
    board.playStone(Position(0,0), StoneColor.BLACK);

    assert(board.playStone(Position(1,0), StoneColor.WHITE) == false, "Allowed white to take ko early.");

    board.playStone(Position(18,18), StoneColor.WHITE);
    board.playStone(Position(17,18), StoneColor.BLACK);

    assert(board.playStone(Position(1,0), StoneColor.WHITE) == true, "Did not allow white to take ko.");


    writeln(board.toString());
}