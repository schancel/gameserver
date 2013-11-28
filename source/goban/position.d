module goban.position;

import std.exception : enforce;

struct Position
{
    ubyte x;
    ubyte y;

    /*** 
     * Construct position from x and y;
     */
    this(ubyte x, ubyte y)
    {
        this.x = x;
        this.y = y;
    }

    /***
     * Convert a an SGF position to an xy position.  
     */
    this(string position)
    {
        enforce( position.length == 2, "Invalid position");
        x = charToInt(position[0]);
        y = charToInt(position[1]);
    }

    /*** 
     * Convert an SGF position to an integer
     *  a = 1, A = 27
     */
    ubyte charToInt(char pos)
    {
        switch(pos)
        {
            case 'a': .. case 'z':
                return cast(ubyte)(pos-'a');
            case 'A': .. case 'Z':
                return cast(ubyte)(pos-'A');
            default: 
                enforce(0, "Invalid position character");
        }

        assert(0, "charToInt: We shouldn't have gotten here!");
    }
}