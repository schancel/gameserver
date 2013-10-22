import vibe.d;
import vibe.core.core;
import vibe.core.driver;
import vibe.http.websockets;
import std.container;
import std.stdio;
import core.time;
import vibe.stream.ssl;
import vibe.core.concurrency;
import vibe.core.log;
import std.conv;
import vibe.data.json;

import std.file;

import Channels;
import Messaging;
import ConnectionInfo;
import GameTree;
import SGFParser;

GameNode[int] kogoNodes;

void initiateWebsocket(HTTPServerRequest req,
		       HTTPServerResponse res)
{
  auto wsd = handleWebSockets( function(WebSocket ws) {
      scope ConnectionInfo ci = new ConnectionInfo(ws);
      
      ci.spawn();
    } );
  
  wsd(req,res);
}

void handleKogoRequest(HTTPServerRequest req,
		       HTTPServerResponse res)
{
  struct ProgressiveRequestData
  {
    int id;
    string pid;
  }


  ProgressiveRequestData p;
  loadFormData(req, p);

  writefln("%s, %s", p.id, p.pid);

  if( p.id == 0) 
    res.writeBody( kogoNodes[1].toSgf );
  else if( auto node = p.id in kogoNodes)
    res.writeBody( (*node).toSgf);
  else
    res.writeBody(";BM[]");
}

shared static this() 
{
  auto router = new URLRouter;
  router
    .get("*", serveStaticFiles("./public/"))
    .get("/js/commands.js", &MessageHandler.outputJavascript)
    .get("/websocket", &initiateWebsocket)
    .get("/", staticRedirect("/index.html"))
    .get("/kogo", &handleKogoRequest);

  auto foo = new SGFParser(readText("kogo.sgf"));
  foreach( GameNode node; foo.root.walkTree)
    {
      kogoNodes[node.NodeID] = node;
    }

  //setLogLevel(LogLevel.trace);
  setLogFile("log.txt");

  auto settings = new HTTPServerSettings;
  settings.port = 8080;
  settings.bindAddresses = ["::"];
  //settings.sslContext = new SSLContext( "server.crt", "server.key");
  
  listenHTTP(settings, router);
}
