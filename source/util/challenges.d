module util.challenges;

//TODO: Make this work.  Need timers on challenges so they go away after awhile. ?

import std.algorithm;
import std.exception :enforce;
import std.string;
import std.datetime;

import util.challenges;
import messages.game;

///Structure to allow us to look up challenges in an AA.
struct ChallengeIndex {
    string player1; //Color independant.  We will look at the ChallengeMessage to find that out.
    string player2;
    SysTime issued; //use this to clean up old challenges.
    
    this(string player1, string player2)
    {
        //Players need to be in the correct order for opCmp to work.
        this.player1 = min(player1.toUpper,player2.toUpper);
        this.player2 = max(player2.toUpper, player1.toUpper);
        issued = Clock.currTime();
    }

    hash_t toHash() const nothrow @safe 
    {
        return typeid(string).getHash(&this.player1) ^ typeid(string).getHash(&this.player2) ;
    }
    
    const bool opEquals(ref const ChallengeIndex s)
    {
        return this.player1 == s.player1 && this.player2 == s.player2;
    }

    //Implement lexicographical order.
    const int opCmp(ref const ChallengeIndex s)
    {
        auto firstCmp = this.player1.cmp(s.player1);
        return firstCmp ? firstCmp : this.player2.cmp(s.player2);
    }
}

private static __gshared ChallengeMessage[ChallengeIndex] challenges;
private static __gshared Object challengeMutex = new Object();

//TODO: Clean up old challenges via a task or something.


ChallengeMessage getChallege(string player1, string player2)
{
    synchronized(challengeMutex) 
    {
        if( auto p = ChallengeIndex(player1,player2) in challenges ) {
            return *p;
        }  else {
            return null;
        }
    }
    
    assert(0, "Shouldn't be here");
}

void registerChallenge(ChallengeMessage msg)
{
    synchronized(challengeMutex) 
    {
        auto idx = ChallengeIndex(msg.white,msg.black);
        enforce(idx !in challenges, "Game already exists?  How is this possible?");

        challenges[idx] == msg;
    }
}

void unregisterChallenge(ChallengeMessage msg)
{
    synchronized(challengeMutex) 
    {
        auto idx = ChallengeIndex(msg.white,msg.black);
        enforce(idx in challenges, "No such challenge.");
        
        challenges.remove(idx);
    }
}
