module goban.rules;

import goban.goban;
import goban.position;
import goban.colors;

interface Rules
{
    bool check(Position pos, StoneColor color);
    void apply(Position pt, StoneColor color);
}

import std.stdio;

class AGARules : Rules
{
    Goban board;
    Position[] pendingCaptures;

    this(Goban board)
    {
        this.board = board;
    }

    /***
     * Called to see whether a stone may be placed at a given point
     * Returns: true = valid move
     * false = invalid move
     **/
    bool check(Position pos, StoneColor color) {
        bool suicide, superko;
      
        // already occupied?
        if (board[pos] != StoneColor.EMPTY) {
            return false;
        }
        
        //commit the current changes so we can play the move to see if it's valid.
        this.board.commit();

        board[pos] = color;
        doCaptures(pos,color);
        
        if( board[pos] == StoneColor.EMPTY )
        {
            //Pop our testing off the board stack.
            board.revert();
            return false;
        }
        
        //Check for superko.  This may become excessively slow... Maybe limit depth to 2?
        foreach_reverse(state; board.previousStates)
        {
            if( board.compareBoard(state) )
            {
                superko = true;
                break; //Stop checking so we don't overwrite our finding of a superko violation.
            }
        }
        
        //Pop our testing off the board stack.
        board.revert();
        
        return !superko;
    }
     
    /***
     * Apply rules to the current game (perform any captures, etc)
     **/
    void apply(Position pt, StoneColor color) {
        doCaptures(pt, color);
    }

    /***
     * Thanks to Arno Hollosi for the capturing algorithm
     */
    void doCaptures(Position pt, StoneColor color) {
        int captures = 0;


        captures += doCapture(Position(pt.x-1, pt.y));
        captures += doCapture(Position(pt.x+1, pt.y));
        captures += doCapture(Position(pt.x, pt.y-1));
        captures += doCapture(Position(pt.x, pt.y+1));

        // check for suicide
        //TODO: Check for suicide
        captures -= this.doCapture(pt);

        board.addCaptures(color, captures);
    }

    int doCapture(Position pt) {
        pendingCaptures.length = 0;

        if (pt.x < 0 || pt.y < 0 || pt.x >= board.size || pt.y >= board.size) {
            return 0;  //No liberty
        }

        if (findCaptures(pt, board[pt])) {
            return 0;
        }

        foreach(pos; pendingCaptures)
        {
            board[pos] =  StoneColor.EMPTY;
        }

        return cast(int)pendingCaptures.length;
    }

    int findCaptures(Position pt, StoneColor color) {
        // out of bounds?
        if (pt.x < 0 || pt.y < 0 || pt.x >= board.size || pt.y >= board.size) {
            return 0;  //No liberty
        }

        // found a liberty
        if (board[pt] == StoneColor.EMPTY) {
            return 1;
        }

        // found opposite color
        if (board[pt] != color) {
            return 0;
        }

        //already visited?
        foreach(pos; pendingCaptures)
        {
            if (pos == pt) {
                return 0;
            }
        }

        pendingCaptures ~= pt;

        if (this.findCaptures(Position(pt.x-1, pt.y), color)) {
            return 1;
        }
        if (this.findCaptures(Position(pt.x+1, pt.y), color)) {
            return 1;
        }
        if (this.findCaptures(Position(pt.x, pt.y-1), color)) {
            return 1;
        }
        if (this.findCaptures(Position(pt.x, pt.y+1), color)) {
            return 1;
        }

        return 0;
    }
}