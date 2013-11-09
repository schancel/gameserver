module user.userinfo;

import std.stdio;
import std.container;
import std.conv;
import std.array;


import user.rank;

enum RelationTypes
{
    None = 0,
    Friend = 1,
    Blocked = 2
}

class UserInfo
{
    private int id;
    private string username;
    private int titleId;
    private Rank rating;
    private RelationTypes[string] relations;

    this( string username = "AnonymousCoward") pure 
    {
        this.Username = username;
    }

    @property public int Id() pure const
    {
        return id;
    }

    @property public string Username() pure const
    {
        return username;
    }

    @property public void Username(string value) pure
    {
        username = value;
    }

    @property public int TitleId() pure const
    {
        return titleId;
    }

    @property public void TitleId(int value) pure 
    {
        titleId = value;
    }

    @property public Rank Rating() pure const
    {
        return rating;
    }

    @property public void Rating(Rank value)
    {
        rating = value;
    }

    public RelationTypes getRelation(string username) pure
    {
        auto friendEntry = username in relations;

        if(friendEntry)
            return *friendEntry; 
        else
            return RelationTypes.None;
    }

    public void setRelation(string username, RelationTypes type) pure
    {
        this.relations[username] = type;
    }
}