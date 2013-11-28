module util.mysql;

import mysql.connection;

public class Database
{
	private static Connection connection;

	public static void connect()
	{
		connection = new Connection(
			config.mySQLHostname.get!string(),
			config.mySQLUsername.get!string(),
			config.mySQLPassword.get!string(),
			config.mySQLDatabase.get!string()
			);
	}

	public static ResultSet query(string query)
	{
		auto cmd = Command(conn);
		cmd.sql = query;
		return cmd.execSQLResult();
	}
}

unittest {
    import std.stdio;
    auto conn = new Connection("localhost", "sujigo","f00b4r", "suji_auth");
    auto cmd = Command(conn);
    ResultSet rs;

    cmd.sql = "SELECT * FROM accounts";
    rs = cmd.execSQLResult();
    foreach(result; rs)
    {
        writeln(result);
    }
}