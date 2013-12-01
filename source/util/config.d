module util.config;

import std.stdio;
import std.file;
import vibe.data.json;
import vibe.core.log;

const Json defaults;
static const string CONFIG_FILE = "config.json";

static private __gshared Configuration __config;

Configuration Config() {
    if(!__config) //Lazy loading
        __config = new Configuration(CONFIG_FILE);

    return __config;
}

class Configuration
{
    //Configuration properties.
    @optional string domainName = "sujigo.com";
    @optional string mySQLHostname = "localhost";
    @optional string mySQLDatabase = "sujigo";
    @optional string mySQLUsername = "sujigo";
    @optional string mySQLPassword = "f00b4r";

    this() {}

    this(string configFile)
	{
        load(configFile);
    }

	public void load(string configFile = CONFIG_FILE)
	{
        if( exists(CONFIG_FILE) )
        {
            Json jsonConfig = parseJsonString(readText(configFile));
            deserializeJson(this, jsonConfig);
            logDebug("Loaded Config");
        } else {
            logDebug("Using default config");
        }
	}

    public void save()
    {
        Json properties = serializeToJson(this);
        auto file = File(CONFIG_FILE, "w");
        auto writer = file.lockingTextWriter();
        writer.writePrettyJsonString(properties);
        logDebug("Config saved.");
    }
}

unittest
{
    assert(Config.mySQLUsername == "sujigo", "Default config file not parsed correctly?");
}

static this()
{
    Config.load();
    Config.save();
}