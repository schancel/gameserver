module util.mysql;

import mysql.connection;
import mysql.db;
import std.exception;

import util.config;

public class Database
{
    static MysqlDB mdb;

    static Command authUserCmd();

	private static auto connect()
	{
        if( !mdb )
            mdb = new MysqlDB(Config.mySQLHostname.get!string(),
                              Config.mySQLUsername.get!string(),
                              Config.mySQLPassword.get!string(),
                              Config.mySQLDatabase.get!string()
                              );

        return mdb.lockConnection();
	}


    import user.userinfo;

	public static UserInfo GetUserInfo(string username)
	{
        auto conn = connect();
        Command cmd = Command(conn);

        cmd.sql = "SELECT username FROM accounts WHERE username = ?";

        cmd.bindParameter(username, 0);
        auto rs = cmd.execSQLResult();
        foreach(row; rs)
            return new UserInfo(row[0].get!string);

        enforce(false, "Unknown user");
        return null;
	}



}

unittest {
    //"localhost", "sujigo","f00b4r", "suji_auth"
    import std.stdio;
    auto conn = new Connection(
        Config.mySQLHostname.get!string(),
        Config.mySQLUsername.get!string(),
        Config.mySQLPassword.get!string(),
        Config.mySQLDatabase.get!string());
    auto cmd = Command(conn);
    ResultSet rs;

    cmd.sql = "SELECT * FROM accounts";
    rs = cmd.execSQLResult();
    foreach(result; rs)
    {
        writeln(result);
    }
}