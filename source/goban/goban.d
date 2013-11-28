module goban.goban;

import goban.rules;
import goban.position;
import goban.colors;
import std.container ;

interface Goban
{
    void revert(uint steps);
    StoneColor opIndexAssign(StoneColor color, Position pos);
    StoneColor opIndex(Position idx);
    bool playStone(Position pos, StoneColor color);
}

class GobanImpl(rulesType) : Goban  if( isRulesType!(rulesType) )
{
    int size;
    StoneColor stones[];
    uint[StoneColor.max] captures;
    alias UndoDelegate = void delegate ();
    Array!(UndoDelegate) undoStack;  //Stores an array of delegates so we can undo moves.

    /***
     * Create a new board.  Requires a board size.  Only square boards are supposed.
     */
    this(int size = 19)
    in
    {
        enforce(size < 36, "Invalid board size");
    }
    body {
        this.size = size;
        stones = new StoneColor[size*size];
    }

     /***
     * Revert to a previous state.
     */
    void revert(uint steps) {
        while( steps-- && ! undoStack.empty() )
        {
            auto undo = undoStack.back();
            undo();
            undoStack.removeBack();
        }
    }

    /*** 
     * Add a stone to the board.  Do not apply rules.
     */
    StoneColor opIndexAssign(StoneColor color, Position pos)
    {
        return stones[pos.x + pos.y*size] = color;
    }

    /*** 
     * Get the stone at a particular position.
     */
    StoneColor opIndex(Position pos)
    {
        return stones[pos.x + pos.y*size];
    }

    /***
     * Place a stone on the board, and apply rules.
     */
    bool playStone(Position pos, StoneColor color)
    {
        if( rulesType.check(this, pos, color))
        {
            this[pos] = color;
            rulesType.apply(this, pos, color);

            return true;
        }

        return false;
    }
}