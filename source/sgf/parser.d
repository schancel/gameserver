module sgf.parser;

private import sgf.gametree;
private import std.container;
private import std.array : Appender;

private import std.string : indexOf;

import util.stringutils;

//TODO: Make this use util.util.readArg; ?

class SGFParser
{
  GameNode root;
  string sgfData;

  this(string data)
  {
    this.root = new GameNode();
    sgfData = data;

    ParseTree();
  }

  void ParseTree()
  {
    Array!(GameNode) nodeStack;
    char c = 0x00;
    int index = 0;

    auto curNode = this.root;
    string curKey;

    string readKey()
    {
      int startIndex = index;

      for( index++; index < sgfData.length; index++ )
        { 
          switch( sgfData[index] )
            {
            case '\r', '[', '(', '\t', ' ', ';', ')':
              return sgfData[startIndex..index];
            default:
              continue; 
            }
        }
      return "";
    }

    string readValue()
    {
      int startIndex = ++index;
      Appender!(string) output;

      for( ; index < sgfData.length; index++ )
        {
          switch( sgfData[index] )
            {
            case '\\':
              output.put(sgfData[startIndex..index]);
              startIndex = ++index;
              break;
            case ']':
              if( output.data.length == 0)
                return sgfData[startIndex..index];
              else 
                {
                  output.put(sgfData[startIndex..index]);
                  return output.data;
                }
            default:
              continue; 
            }
        }
      return "";
    }

    for( index = 0; index < sgfData.length; index++)
      {

        switch (sgfData[index]) 
          {
          case ';':
            curNode = curNode.appendChild();
            break;
          case '(':
            nodeStack.insertBack(curNode);
            break;
          case ')':
            curNode = (nodeStack.back());
            nodeStack.removeBack();
            break;
          case '[':
            curNode.pushProperty(curKey, readValue());
            index--;
            break;
          case ' ', '\t', '\r', '\n', ']':
            break;
          default:
            curKey = readKey();
            index--;
          }
      }
  }
}