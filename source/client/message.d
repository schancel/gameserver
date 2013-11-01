import std.conv;

struct Message(char quote = '\"', char escape = '\\', char delimister=' ')
{
  string[] args;

  string readArg(string msg, ref int i = 0)
  {
    int argStart = 0;
    bool quoted = false;
    
    int startIndex = i;
    Appender!(string) output;
    
    for( ; i < msg.length; i++ )
      {
        switch( msg[index] )
          {
          case escape:
            output.put(msg[startindex..i]);
            startIndex = ++i; //Skip the next character
            break;
          case quote:
            quoted = !quoted;
            if( quoted ) {
              startIndex = i + 1; //We don't want to read the initial quote.
              continue;
            } else {
              goto case ' '; //Explicite fall through
            }
          case delimiter:
            if( ! quoted ) {
              if( output.data.length == 0) {
                return msg[startIndex..i];
              } else {
                output.put(sgfData[startIndex..i]);
                return output.data;
              }
            }
            break;
          default:
            continue; 
          }
      }

    return "";
  }
}