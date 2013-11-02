module user.rank;

import std.format : formattedWrite;
import std.conv;
import std.exception : enforce;
import std.array;
import std.algorithm : min;
import std.math : sqrt, pow, abs;


static immutable int DAN_RANK = 17;
static immutable int PRO_RANK = 26; //TODO: Implement this in the conversions.
static immutable int RANK_DIFFERENCE = 1;

struct Rank //Implement ELO ratings and their conversion to Go ranks.
{ 
  double rating;
  double uncertainty;
  int games;
  /**
   * Constructor for rank.  Takes in rating and uncertainty.

   * _rating    = Existing rating for user.  Presumably from database, or user input.
   * uncertaint = Uncertainty for rank.   The default value is very large as we don't know what a new rank is yet.
   *              This is used in the algorithm for adjustments.
   */
  this (int _rating = 0, double _uncertainty = 10000000, int _games = 0)
  {
    rating = _rating;
    uncertainty = _uncertainty;
    games = _games;
  }

  this (string _rating)
  {
    enforce( _rating.length >= 2, "Invalid rank");
    enforce( _rating[$-1] == 'd' || _rating[$-1] == 'k', "Invalid rank");

    rating = to!int(_rating[$-2]);

    switch( _rating[$-1])
      {
      case 'k':
        rating = DAN_RANK - rating * RANK_DIFFERENCE;
        break;
      case 'd':
        rating = rating * RANK_DIFFERENCE + DAN_RANK;
        break;
      default: 
        rating = 0;
      }
  }

  string toString()
  {
    auto writer = appender!string();
    
    if( rating > DAN_RANK ) {
      formattedWrite( writer, "%sd", rating - DAN_RANK / RANK_DIFFERENCE );
    } else {
      formattedWrite( writer, "%sk", abs(rating - DAN_RANK) / RANK_DIFFERENCE );
    }
    return writer.data;
  }
}

//TODO: Support komi
void AdjustRanks( ref Rank winner, ref Rank loser, int handicap, int komi )
{
  //Note: Represents a 66% chance of winning, if you are 1 rank above the person.
  double Qw = pow(2, winner.rating );
  double Ql = pow(2, loser.rating );


  winner.rating = winner.rating + (1 - (Qw/(Qw+Ql))) * 1/loser.uncertainty;
  loser.rating = loser.rating - (Ql/(Qw+Ql)) * 1/winner.uncertainty;

  winner.games += 1;
  loser.games += 1;

  //TODO: Figure out how to properly gauge uncertainty unjustments.
  winner.uncertainty = min(sqrt(winner.uncertainty * 1/loser.uncertainty), 1); //Minimum rank uncertainty;
  loser.uncertainty = min(sqrt(loser.uncertainty * 1/winner.uncertainty), 1);
}