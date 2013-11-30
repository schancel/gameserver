module goban.colors;

import std.algorithm;

const auto colorProperties = ["B", "W", "R", "G", "V"];

enum StoneColor
{
    EMPTY = 0,
    BLACK = 1,
    WHITE = 2,
    RED = 3,
    GREEN = 4,
    VIOLET = 5,
}

StoneColor getStoneColor(string color)
{
    long colorIdx = colorProperties.countUntil(color);
    return cast(StoneColor)(colorIdx >= 0 && colorIdx < StoneColor.max -1) ? cast(StoneColor)(colorIdx+1) :StoneColor.EMPTY;
}

string getColorString(StoneColor color)
{
    return colorProperties[cast(size_t)color -1];
}