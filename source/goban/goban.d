module goban.goban;

import goban.rules;
import goban.position;
import goban.colors;
import std.container ;

interface Goban
{
    void revert();
    void commit();
    StoneColor opIndexAssign(StoneColor color, Position pos);
    StoneColor opIndex(Position idx);
    bool playStone(Position pos, StoneColor color);

    bool compareBoard(BoardState);

    @property int size();

    void addCaptures(StoneColor, int captures);

    @property Array!(BoardState) previousStates();
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

    @property int size()
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
            rules.apply( pos, color);

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
}