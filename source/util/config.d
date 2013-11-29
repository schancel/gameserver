module util.config;

import std.stdio;
import std.file;
import vibe.data.json;
import vibe.core.log;

const Json defaults;

const string defaultConfig = `{
    "mySQLHostname": "localhost",
    "mySQLDatabase": "sujigo",
    "mySQLUsername": "sujigo",
    "mySQLPassword": "f00b4r"
}`;

class Config
{
    static const string CONFIG_FILE = "config.json";

	this()
	{
		// Constructor code
	}

	public static Json properties;

	public static void load()
	{
        if( exists(CONFIG_FILE) )
        {
            properties = parseJsonString(readText(CONFIG_FILE));
            logDebug("Loaded Config");
        } else {
            logDebug("Using default config");
            properties = parseJsonString(defaultConfig);
        }
	}

    public static auto opDispatch(string name)()
    {
        auto prop =  properties[name];
        if( prop.type == Json.Type.undefined )
        {
            return defaults[name];
        } else {
            return prop;
        }
    }

    public static void save()
    {
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
    defaults = parseJsonString(defaultConfig);
    Config.load();
    Config.save();
}