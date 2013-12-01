module util.igs;

import std.conv;
import std.exception;

//Move format does not include the letter "i".  What a pain in the ass.

string igsToSgf(string pos)
{
    string sgfPos;
    sgfPos.reserve(3);

    switch( pos[0] ) //Doesn't support large boards, because IGS sucks.
    {
        case 'a': .. case 'h':
            sgfPos ~= pos[0];
            break;
        case 'j': .. case 'z':  //Calculate correct position for > i
            sgfPos ~= pos[0] - '\x01';
            break;
        default:
            enforce(false, "Invalid position");
    }
    sgfPos ~= cast(char)(pos[1..$].to!byte) + 'a' - '\x01';

    return sgfPos;
}

string sgfToIgs(string pos)
{
    string igsPos;
    igsPos.reserve(3);
    switch( pos[0] ) //Doesn't support large boards, because IGS sucks.
    {
        case 'a': .. case 'h':
            igsPos ~= pos[0];
            break;
        case 'i': .. case 'y':  //Calculate correct position for > i
            igsPos ~= pos[0] + '\x01';
            break;
        default:
            enforce(false, "Invalid position");
    }
    igsPos ~= (pos[1] - 'a').to!string;
    
    return igsPos;
}


