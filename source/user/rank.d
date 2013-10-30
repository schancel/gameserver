module user.rank;

import std.format : formattedWrite;
import std.conv;
import std.exception : enforce;
import std.array;
import std.math;



struct Rank //Implement ELO ratings and their conversion to Go ranks.
{ 
  static immutable int DAN_RANK = 1700;
  static immutable int RANK_DIFFERENCE = 100;
  int rating;

  this (int _rating = 0)
  {
    rating = _rating;
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