module goban.rules;

import goban.goban;
import goban.position;
import goban.colors;

template isRulesType(rules)
{
    enum isRulesType = true;
    /*
    enum isRulesType = is(typeof( 
    (inout int = 0)
    {
        if( rules.check(new GobanTest(), Position(0,0), StoneColor.EMPTY) )
        {}

        rules.apply(new GobanTest(), Position(0,0), StoneColor.EMPTY);
    }));*/
}

pragma(msg, isRulesType!(AGARules));

class AGARules
{
    /***
     * Called to see whether a stone may be placed at a given point
     * Returns: true = valid move
     * false = invalid move
     **/
    static bool check(Goban board, Position pos, StoneColor color) {
        bool suicide, superko;
        /*i;
        // already occupied?
        
        if (this.board.getStone(pt) != this.board.EMPTY) {
            return false;
        }
        
        //commit the current changes so we can play the move to see if it's valid.
        this.board.commit();
        
        this.board.addStone(pt,color);
        this.doCaptures(pt,color);
        
        suicide = this.board.getStone(pt) === this.board.EMPTY;
        
        //check for superko.  This may become excessively slow... Maybe limit depth to 2?
        superko = false;
        cacheLen = this.board.cache.length;
        
        for(i = 0; i < this.board.cache.length; i++)
        {
            if( this.board.compare(this.board.cache[i]) )
            {
                superko = true;
                break; //Stop checking so we don't overwrite our finding of a superko violation.
            }
        }
        
        //Pop our testing off the board stack.
        this.board.revert(1);
        
        return !( suicide || superko);
        */

        return true;
    }
     
    /***
     * Apply rules to the current game (perform any captures, etc)
     **/
    static void apply(Goban board, Position pt, StoneColor color) {
        doCaptures(pt, color);
    }

    /***
     * Thanks to Arno Hollosi for the capturing algorithm
     */
    static void doCaptures(Position pt, StoneColor color) {
        /*uint captures = 0;

        captures += this.doCapture({x: pt.x-1, y: pt.y}, color);
        captures += this.doCapture({x: pt.x+1, y: pt.y}, color);
        captures += this.doCapture({x: pt.x, y: pt.y-1}, color);
        captures += this.doCapture({x: pt.x, y: pt.y+1}, color);

        // check for suicide
        captures -= this.doCapture(pt, -color);

        if (captures < 0) {
            // make sure suicides give proper points (some rulesets allow it)
            color = -color;
            captures = -captures;
        }

        color = (color === this.board.WHITE ? "W" : "B");
        this.board.captures[color] += captures;*/
    }

    static uint doCapture(Position pt, StoneColor color) {
        /*uint caps;
        this.pendingCaptures = [];
        
        if (this.findCaptures(pt, color)) {
            return 0;
        }
        
        caps = this.pendingCaptures.length;
        
        while (this.pendingCaptures.length) {
            this.board.addStone(this.pendingCaptures.pop(), this.board.EMPTY);
        }
        return caps;*/

        return 0;
    }

    static void findCaptures(Position pt, StoneColor color) {
        /*
        var i;
        
        // out of bounds?
        if (pt.x < 0 || pt.y < 0 || pt.x >= this.board.boardSize || pt.y >= this.board.boardSize) {
            return 0;
        }
        
        // found opposite color
        if (this.board.getStone(pt) === color) {
            return 0;
        }
        // found a liberty
        if (this.board.getStone(pt) === this.board.EMPTY) {
            return 1;
        }
        // already visited?
        for (i = 0; i < this.pendingCaptures.length; i++) {
            if (this.pendingCaptures[i].x === pt.x && this.pendingCaptures[i].y === pt.y) {
                return 0;
            }
        }
        
        this.pendingCaptures.push(pt);
        
        if (this.findCaptures({x: pt.x-1, y: pt.y}, color)) {
            return 1;
        }
        if (this.findCaptures({x: pt.x+1, y: pt.y}, color)) {
            return 1;
        }
        if (this.findCaptures({x: pt.x, y: pt.y-1}, color)) {
            return 1;
        }
        if (this.findCaptures({x: pt.x, y: pt.y+1}, color)) {
            return 1;
        }
        return 0;
        */
    }
}