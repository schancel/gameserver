private import GameTree;
private import std.container;

private import std.string : indexOf;

class SGFParser
{
  GameNode root;
  string sgfData;
  int index = 0;

  this(string data)
  {
    this.root = new GameNode();
    sgfData = data;

    ParseTree();
  }

  void ParseTree()
  {
    Array!(GameNode*) nodeStack;
    char c = 0x00;

    auto curNode = this.root;

    for( index = 0; index < sgfData.length; index++) {

      switch (sgfData[index]) {
      case ';':
        curNode = curNode.appendChild();
        parseProperties(curNode);
        break;
      case '(':
        nodeStack.insertBack(&curNode);
        break;
      case ')':
        curNode = *(nodeStack.back());
        nodeStack[].popBack();
        break;
      default:
        break;
      }
    }

  }

  void parseProperties(GameNode curNode)
  {
    string curKey;

    string readKey()
    {
      int startIndex = index;

      for( ; index < sgfData.length; index++ )
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
      for( ; index < sgfData.length; index++ )
        {
          switch( sgfData[index] )
            {
            case '\\':
              index++; //TODO: Filter these outsomehow.
              break;
            case ']':
              return sgfData[startIndex..index];
            default:
              continue; 
            }
        }
      return "";
    }
    
    for( this.index++; index < sgfData.length; index++ )
      { 
        switch( sgfData[index] )
          {
          case '(', ')', ';':
            index--;
            return;
          case '[':
            curNode.pushProperty(curKey, readValue());
            break;
          case ' ', '\t', '\r', '\n':
            break;
          default:
            curKey = readKey();
            index--;
          }
      }
  }
}