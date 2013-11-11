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

import client.connection;
import client.igsconnection;
import client.wsconnection;
import client.messages;

void initiateWebsocket(HTTPServerRequest req,
                       HTTPServerResponse res)
{
    auto wsd = handleWebSockets( function(WebSocket ws) {
        scope auto ci = new WSConnection(ws);
        
        ci.spawn();
    } );
    
    wsd(req,res);
}

void initiateTelnet(TCPConnection conn)
{
    scope auto ci = new IGSConnection(conn);
    
    ci.spawn();
}

static this() 
{
    auto router = new URLRouter;

    router
        .get("*", serveStaticFiles("./public/"))
            .get("/websocket", &initiateWebsocket) 
            .get("/js/rpc_bindings.js", (req, res) { immutable string jsBindings = JavascriptBindings(); res.writeBody(jsBindings); })
            .get("/", staticRedirect("/index.html"));

    setLogLevel(LogLevel.diagnostic);
    setLogFile("log.txt");

    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["::"];
    //settings.sslContext = new SSLContext( "server.crt", "server.key"); //Support for SSL certificates.

    //Lets support IGS also.
    runTask(() {
        listenTCP_s(6969, &initiateTelnet, settings.bindAddresses[0]);// This blocks, so we need to spawn another event loop.
    });

    listenHTTP(settings, router);
}