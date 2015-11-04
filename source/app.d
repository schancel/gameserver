import core.time;

import std.stdio;

import vibe.d;

import connections;
import connections.igsconnection;
import connections.wsconnection;
import util.config;

import messages.core;

void initateWebSocket(scope WebSocket ws) {
    scope auto ci = new WSConnection(ws);
    
    ci.spawn();
}

void initiateTelnet(scope TCPConnection conn)
{
    scope auto ci = new IGSConnection(conn);

    ci.spawn();
}

static this() 
{
    auto router = new URLRouter;
    router
        .get("*", serveStaticFiles("./public/"))
            .get("/websocket", handleWebSockets( &initateWebSocket ) ) 
            .get("/js/rpc_bindings.js", (req, res) { static immutable string jsBindings = JavascriptBindings(); res.writeBody(jsBindings); })
            .get("/", staticRedirect("/index.html"));

    debug
    {
        setLogLevel(LogLevel.debugV);
    } else {
        setLogLevel(LogLevel.info);
    }

    setLogFile("log.txt");

    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    //settings.sslContext = new SSLContext( "server.crt", "server.key"); //Support for SSL certificates.

    //Lets support IGS also.
    listenTCP_s(6969, &initiateTelnet);// This blocks, so we need to spawn another event loop.
    listenHTTP(settings, router);
}