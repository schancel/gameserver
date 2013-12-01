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
        __config = Configuration.load(CONFIG_FILE);

    return __config;
}

class Configuration
{
    //Configuration properties.
    string domainName = "sujigo.com";
    string mySQLHostname = "localhost";
    string mySQLDatabase = "sujigo";
    string mySQLUsername = "sujigo";
    string mySQLPassword = "f00b4r";

    this() {}


	public static Configuration load(string configFile = CONFIG_FILE)
	{
        if( exists(CONFIG_FILE) )
        {
            Json jsonConfig = parseJsonString(readText(configFile));
            Configuration output;
            deserializeJson(output, jsonConfig);
            logDebug("Loaded Config");
            return output;
        } else {
            logDebug("Using default config");
            return new Configuration();
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
    static if(0)
        assert(Config.mySQLPassword == "f00b", "Config not parsed correctly?");
}
