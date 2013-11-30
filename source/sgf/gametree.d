module sgf.gametree;

import std.stdio;
import std.container;
import std.conv;
import std.array;

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

    GameNode appendChild(GameNode newChild)
    {
        Children ~= newChild;
        return newChild;
    }

    int walkTree(int delegate(ref GameNode) dg)
    {
        GameNode start = this;

        auto nodeStack = make!(Array!(GameNode))(start);
        int result = 0;
        
        while ( ! nodeStack.empty ) {
            auto curNode = (nodeStack.back());
            nodeStack.removeBack();
            
            result = dg(curNode);
            if( result ) return result;
            
            foreach( GameNode child; curNode.Children )
            {
                nodeStack.insertBack(child);
            }
        }
        
        return 0;
    }

    string toSgf(int depth = int.max) const
    {
        auto str = appender!(string);

        str.put(";");
        /+str.put(";_id[");
        str.put(to!string(this.NodeID));
        str.put("]");+/

        foreach( key, arr; Properties )
        {
            str.put(key);
            foreach(value; arr)
            {
                str.put("[");
                str.put(value);
                str.put("]");
            }
        }
        
        if( depth > 0 )
            foreach( child; Children)
        { 
            if( this.Children.length > 1 ) str.put('(');
            str.put( child.toSgf(depth-1) );
            if( this.Children.length > 1 ) str.put(')');
            
        }

        return str.data;
    }
}