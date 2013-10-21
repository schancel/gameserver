import std.stdio;

class GameNode
{
  static int nextNodeId = 0;

  int MoveNumber;
  int NodeID = 0;
  string[][string] Properties;
  GameNode[] Children;
  GameNode Parent;

  this()
  {
    Parent = null;
    NodeID = ++nextNodeId;
  }

  this(GameNode _parent)
  {
    Parent = _parent;
    NodeID = ++nextNodeId;
  }

  void pushProperty(string key, string value)
  {
    if( auto arr = (key in Properties) ) {
      (*arr) ~= value;
    } else {
      Properties[key] = [value];
    }
  }
  
  GameNode appendChild()
  {
    GameNode newChild = new GameNode(this);
    Children ~= newChild;
    return newChild;
  }

  GameNode walkTree()
  {

    yield

  }
}