module util.stringutils;

import std.array;
/**
 * Destructively read a argument, and return it.  May allocate if there are escape characters in the string
 *
 */
private enum {
    START = 1,
    READING,
    QUOTED, 
    END
}

string readArg(char quote = '\"', char escape = '\\', char delimiter = ' ')(ref string msg)
{
    bool quoted = false;
    int startIndex = 0, endIndex = 0;
    Appender!(string) output;

    int i = 0;
    short state = START;

    for( ; i < msg.length; i++ )
    {
        switch( msg[i] )
        {
            case escape:
                if( state == END) goto end; //Goto end, don't want to destroy the next argument.
                if(state == READING) output.put(msg[startIndex..i]);
                startIndex = ++i; //Skip next item.
                if( state == START) state = READING;
                break;
            case quote:
                final switch( state )
                {
                    case START:
                        startIndex++;
                        state = QUOTED;
                        break;
                        
                    case READING:
                        break;
                        
                    case QUOTED:
                        state = END;
                        endIndex = i;
                        break;
                        
                    case END:
                        goto end;
                }
                break;
            case delimiter:
                final switch( state )
                {
                    case START:
                        startIndex = i+1; //Ignore delimiter.
                        break;
                        
                    case READING:
                        state = END;
                        endIndex = i;
                        break;
                        
                    case QUOTED: //Do nothing
                        break;
                        
                    case END:
                        //Do Nothing
                        break;
                }
                break;
            default:
                final switch( state )
                {
                    case START:
                        state = READING;
                        break;
                        
                    case READING:
                        break;
                        
                    case QUOTED:
                        break;
                        
                    case END:
                        goto end;
                }
                break;
        }
    }

end:
    string arg;
    if( i <= msg.length && state == END)
    {
        arg = msg[startIndex..endIndex];
        msg = msg[i..$];
    } else { //String ended before end-state, grab everything.
        arg = msg[startIndex..i];
        msg = msg[$..$];
    }

    if( output.data.length == 0) {
        return arg;
    } else {
        output.put(arg);
        return output.data;
    }

    assert(false, "We shouldn't be here");
}

alias readAll(char quote = '"', char escape = '\\')  = readArg!(quote, escape, 0x00);

unittest {
    import std.stdio;
    auto msg = "TELL \"Side Effect\" \"Hello how are you?\"";
    auto arg = msg.readArg();
    assert( arg == "TELL", "First arg wrong:" ~arg ~ " Msg:" ~ msg);
    arg = msg.readArg(); 
    assert( arg == "Side Effect", "Second arg wrong: " ~arg ~ " Msg: " ~ msg);
    arg = msg.readArg(); 
    assert( arg == "Hello how are you?", "Third arg wrong: " ~arg ~ " Msg: " ~ msg);

    msg = "TELL \"Side Effect\" He\"llo how are you?\"";
    arg = msg.readArg();
    assert( arg == "TELL", "First arg wrong:" ~arg ~ " Msg:" ~ msg);
    arg = msg.readArg(); 
    assert( arg == "Side Effect", "Second arg wrong: " ~arg ~ " Msg: " ~ msg);
    arg = msg.readAll(); 
    assert( arg == "He\"llo how are you?\"", "Third arg wrong: " ~arg ~ " Msg: " ~ msg);
}