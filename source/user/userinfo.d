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

shared class UserInfo
{
    private int id;
    private string username;
    private int titleId;
    private Rank rating;
    private RelationTypes[string] relations;

    this( string username = "AnonymousCoward")
    {
        this.Username = username;
    }

    @property public int Id()
    {
        return id;
    }

    @property public string Username()
    {
        return username;
    }

    @property public void Username(string value)
    {
        username = value;
    }

    @property public int TitleId()
    {
        return titleId;
    }

    @property public void TitleId(int value)
    {
        titleId = value;
    }

    @property public Rank Rating()
    {
        return rating;
    }

    @property public void Rating(Rank value)
    {
        rating = value;
    }

    public RelationTypes getRelation(string username)
    {
        auto friendEntry = username in relations;

        if(friendEntry)
            return *friendEntry; 
        else
            return RelationTypes.None;
    }

    public void setRelation(string username, RelationTypes type)
    {
        this.relations[username] = type;
    }
}