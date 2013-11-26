module source.util.config;
import std.stdio;
import std.file;
import vibe.data.json;

class config
{
	this()
	{
		// Constructor code
	}

	public static Json properties;
	public alias properties this;

	public static void load()
	{
		properties = parseJsonString(readText("config.json"));
		debug writeln("Loaded Config");
	}
}

