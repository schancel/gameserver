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
                    output.put(".");
                    break;
                case StoneColor.WHITE:
                    output.put("O");
                    break;
                case StoneColor.BLACK:
                    output.put("X");
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