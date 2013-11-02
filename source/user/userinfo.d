import std.stdio;
import std.container;
import std.conv;
import std.array;

import redis;

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
	private int rating;
	private RelationTypes[string] relations;

	@property public int Id()
	{
		return id;
	}

	@property public string Username()
	{
		return username;
	}

	@property public int TitleId()
	{
		return titleId;
	}

	@property public int Rating()
	{
		return rating;
	}

	public RelationTypes getRelation(string username)
	{
		auto friendEntry = username in relations;
		if(friendEntry) return *friendEntry; 
		else return RelationTypes.None;
	}

	public void setRelation(string username, RelationTypes type)
	{
		this.relations[username] = type;
	}
}