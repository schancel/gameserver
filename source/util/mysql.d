module util.mysql;

import mysql.connection;
import mysql.db;
import std.exception;

import util.config;

public class Database
{
    private static MysqlDB _mdb;

    static Command authUserCmd();

	@property private static auto mdb()
	{
        if( !_mdb )
            _mdb = new MysqlDB(Config.mySQLHostname,
                              Config.mySQLUsername,
                              Config.mySQLPassword,
                              Config.mySQLDatabase
                              );

        return _mdb;
	}


    import user.userinfo;

	public static UserInfo GetUserInfo(string username)
	{
        import std.stdio;

        auto conn = mdb.lockConnection();
        Command cmd = Command(conn);

        cmd.sql = "SELECT username FROM accounts WHERE username=?";
        cmd.prepare();
        writeln("Hrm");
        cmd.bindParameter(username, 0);
        writeln("Hrm");

        auto rs = cmd.execPreparedResult();
        foreach(row; rs)
            return new UserInfo(row[0].get!string);

        enforce(false, "Unknown user");
        return null;
    }

    static public bool AuthUser(string username, string password)
    {
        import std.stdio;
        
        auto conn = mdb.lockConnection();
        Command cmd = Command(conn);

        byte reply;
        cmd.sql="";
        cmd.execFunction("auth_account", reply, username, password);
       
        return reply != 0;
    }
}

unittest {
    import std.stdio;
    writeln(Database.GetUserInfo("eluusive").Username);
    writeln(Database.AuthUser("eluusive", "testie"));
}