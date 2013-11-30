module connections.igscodes;

/***
 * These are the possible values for in parray.session.protostate.
 * They are used as the first second number in the client-type numerical prompt.
 * For more information on these #$%^$%## defines, look at client source
 * code, such as xigc. What a horrible way to live.
 * 
 * TODO: This code is GPL licensed??? Stolen from NNGS.
 */

enum IGS_CODES
{
    NONE = 0,
    PROMPT = 1,
    BEEP = 2,
    DOWN = 4,
    ERROR = 5,
    FILE = 6,
    GAMES = 7,
    HELP = 8,
    INFO = 9,
    LAST = 10,
    KIBITZ = 11,
    LOAD = 12,
    LOOK_M = 13,
    MESSAGE = 14,
    MOVE = 15,
    OBSERVE = 16,
    REFRESH = 17,
    SAVED = 18,
    SAY = 19,
    SCORE_M = 20,
    SHOUT = 21,
    STATUS = 22,
    STORED = 23,
    TELL = 24,
    THIST = 25,
    TIME = 26,
    WHO = 27,
    UNDO = 28,
    SHOW = 29,
    TRANS = 30,
    YELL = 32,
    TEACH = 33,
    MVERSION = 39,
    DOT = 40,
    CLIVRFY = 41,
    /* PEM: Removing stones.  (???) */
    REMOVED = 49,
    EMOTE = 500,
    EMOTETO = 501,
    PING = 502,
}

/***These are used for the second number on the protocol lines
 * when the first number is '1' (CODE_PROMPT)
 * AvK:
 * grabbed these (5-10) from playerdb.h
 * Added 0-4 from IGS docs
 */

enum IGS_States
{
    LOGON = 0,         /* Unused */
    PASSWORD,          /* Unused */
    PASSWORD_NEW,	   /* Unused */
    PASSWORD_CONFIRM,  /* Unused */
    REGISTER,          /* Unused */
    WAITING,
    PLAYING_GO,
    SCORING,
    OBSERVING,
    TEACHING,          /* Unused */
    COMPLETE	       /* Unused */
}
