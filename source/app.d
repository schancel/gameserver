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

import Channels;
import Messaging;
import ConnectionInfo;

void initiateWebsocket(HTTPServerRequest req,
		       HTTPServerResponse res)
{
  auto wsd = handleWebSockets( function(WebSocket ws) {
      ConnectionInfo ci = new ConnectionInfo(ws);
      
      scope(exit) { ci.destroy(); }
      ci.spawn();
    } );
  
  wsd(req,res);
}

void handleRootRequest(HTTPServerRequest req,
		       HTTPServerResponse res)
{
  res.redirect("/index.html");
}

shared static this() 
{
  auto router = new URLRouter;
  router
    .get("*", serveStaticFiles("./public/"))
    .get("/websocket", &initiateWebsocket)
    .get("/", &handleRootRequest);
  
  //setLogLevel(LogLevel.trace);
  setLogFile("log.txt");

  auto settings = new HTTPServerSettings;
  settings.port = 8080;
  settings.bindAddresses = ["::"];
  //settings.sslContext = new SSLContext( "server.crt", "server.key");
  
  listenHTTP(settings, router);
}
