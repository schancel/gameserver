module util.mysql;

import mysql.connection;


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