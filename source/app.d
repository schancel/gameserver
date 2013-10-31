import core.time;

import std.container;
import std.stdio;
import std.conv;
import std.file;

import vibe.d;
import vibe.core.core;
import vibe.core.driver;
import vibe.http.websockets;
import vibe.stream.ssl;
import vibe.core.concurrency;
import vibe.core.log;
import vibe.data.json;

import gameserver.channels;
import client.messaging;
import client.connection;
import sgf.gametree;
import sgf.parser;


GameNode[int] kogoNodes;

void initiateWebsocket(HTTPServerRequest req,
		       HTTPServerResponse res)
{
  auto wsd = handleWebSockets( function(WebSocket ws) {
      scope WebsocketConnection ci = new WebsocketConnection(ws);
      
      ci.spawn();
    } );
  
  wsd(req,res);
}

void initiateTelnet(TCPConnection conn)
{
  scope TelnetConnection ci = new TelnetConnection(conn);
      
  ci.spawn();
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

  //This is just temporary to support KOGO's joseki dictionary.
  auto foo = new SGFParser(readText("test.sgf"));
  foreach( GameNode node; foo.root.walkTree)
    {
      kogoNodes[node.NodeID] = node;
    }

  setLogFile("log.txt");

  auto settings = new HTTPServerSettings;
  settings.port = 8080;
  settings.bindAddresses = ["::"];
  //settings.sslContext = new SSLContext( "server.crt", "server.key"); //Support for SSL certificates.


  //Lets support Telnet too.   Maybe we can include support for IGS clients?
  runTask(() {
      listenTCP_s(6969, &initiateTelnet, settings.bindAddresses[0]);// This blocks, so we need to spawn another event loop.
    });

  listenHTTP(settings, router);
}


//This is not relevant for our server...  Just a test.
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