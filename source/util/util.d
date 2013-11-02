module util.util;

import std.array;
/**
 * Destructively read a argument, and return it.  May allocate if there are escape characters in the string
 *
 */
string readArg(char quote = '\"', char escape = '\\', char delimiter = ' ')(ref string msg)
{
    bool quoted = false;
    int startIndex = 0;
    Appender!(string) output;

    int i = 0;
    for( ; i < msg.length; i++ )
    {
        switch( msg[i] )
        {
            case escape:
                output.put(msg[startIndex..i]);
                startIndex = ++i; //Skip the next character
                break;
            case quote:
                quoted = !quoted;
                if( quoted ) {
                    startIndex = i + 1; //We don't want to read the initial quote.
                    break;
                } else {
                    goto case delimiter; //Explicite fall through
                }
            case delimiter:
                if( ! quoted ) {
                    goto end;
                }
                break;
            default:
                continue; 
        }
    }

end:
    auto arg = msg[startIndex..i];
    if( i+1 < msg.length )
        msg = msg[i+1..$]; //remove the delimiter
    else
        msg = msg[$..$];

    if( output.data.length == 0) {
        return arg;
    } else {
        output.put(arg);
        return output.data;
    }

    assert(false, "We shouldn't be here");
}

alias readAll = readArg!('"', '\\', 0x00);

unittest {
    import std.stdio;
    auto msg = "TELL \"Side Effect\" \"Hello how are you?";
    auto arg = msg.readArg();
    assert( arg == "TELL", "First arg wrong:" ~arg ~ " Msg:" ~ msg);
    arg = msg.readArg(); 
    assert( arg == "Side Effect", "Second arg wrong: " ~arg ~ " Msg: " ~ msg);
    arg = msg.readAll(); 
    assert( arg == "Hello how are you?", "Third arg wrong: " ~arg ~ " Msg: " ~ msg);

}