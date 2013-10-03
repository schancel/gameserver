private import vibe.d;
private import core.time;
private import vibe.core.concurrency;
private import std.conv;
private import std.stdio;
private import std.traits;
private import vibe.data.json;

private import Channels;
private import ConnectionInfo;

alias immutable(string)[] MessageType;

class MessageHandler
{
  private ConnectionInfo ci;

  this(ConnectionInfo _ci)
  {
    ci = _ci;
  }

  void handleMessage(Json msg)
  {
    string cmd = msg[0].get!string();
    switch( cmd )
      {
	/*
	  Abuse the runtime-reflextions to delegate out 
	*/
	foreach(memberFunc; __traits(allMembers, MessageHandler) )
	  {
	    static if ( memberFunc.startsWith("cmd") )
	      {
	      case memberFunc[3..$]:
		alias ParameterTypeTuple!(MemberFunctionsTuple!(MessageHandler, memberFunc)) ArgTypes;
		enforce(ArgTypes.length + 1 == msg.length, "Improper number of arguments");
		ArgTypes args;
		foreach(i, arg; ArgTypes)
		  {
		    args[i] = (msg[i+1]).get!arg();
		  }
		MemberFunctionsTuple!(MessageHandler, memberFunc)[0](args);
		goto end;
	      }
	  }
      default:
	enforce(false, "Unsupported command: " ~ cmd);
	break;
      }
  end:
    return;
  }

  static void outputJavascript(HTTPServerRequest req,
			       HTTPServerResponse res)
  {

    auto writer = res.bodyWriter();
    /*
      Abuse the runtime-reflextions output stub functions we need.
    */
    foreach(memberFunc; __traits(allMembers, MessageHandler) )
      {
	static if ( memberFunc.startsWith("cmd") )
	  {
	    //alias ParameterTypeTuple!(MemberFunctionsTuple!(MessageHandler, memberFunc)) ArgTypes;
	    alias ParameterIdentifierTuple!(MemberFunctionsTuple!(MessageHandler, memberFunc)) ArgNames;
		
	    writer.write("ServerConnection.prototype."); 
	    writer.write(memberFunc[3..$]);
	    writer.write(" = function(");
		  
	    foreach(i, arg; ArgNames)
	      {
		writer.write(arg);
		if( i != ArgNames.length - 1)
		  writer.write(",");
	      }

	    writer.write(") {  this.doSend(['"); 
	    writer.write(memberFunc[3..$]); 
	    writer.write("',");

	    foreach(i, arg; ArgNames)
	      {
		writer.write(arg);
		if( i != ArgNames.length - 1)
		  writer.write(",");
	      }
	    writer.write("]);};");
	  }
      }
  }

  void cmdJoin(string channel){
    writefln("%s: Joined channel %s", ci.username, channel);
    ci.send(["JOIN", channel]);
    subscribeToChannel( ci, channel );
  }
    
  void cmdPart(string channel)
  {
    writefln("%s: Parted channel %s", ci.username,channel);
    ci.send(["PART", channel]);
    unsubscribeToChannel( ci, channel );
  }

  void cmdNick(string newName)
  {
    writefln("%s: Changed name to %s ", ci.username, newName);
    ci.username = newName;
  }

  void cmdMsg(string channel, string message)
  {
    writefln("%s: Sent message to #%s: %s", ci.username, channel, message);
    sendToChannel(channel, ["MSG", channel, message, ci.username]);
  }
  
  void cmdWho(string channel)
  {
    writefln("%s: WHO #%s", ci.username, channel);
    string[] who;
    foreach(curCi; Channel.getChannel(channel).subscriptions.byKey())
      who ~= curCi.username;


    ci.send(["WHO", channel, serializeToJson(who).toString]);
  }
}