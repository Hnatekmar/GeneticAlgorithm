module decoder;

import std.bitmanip;
import std.range;
import std.meta;
import std.conv;


BitArray subArray(ref BitArray array, size_t from, size_t to)
in
{
    assert(from < to, "From has to be smaller than to and they cannot equal");
}
body
{
    BitArray result;
    for(size_t index = from; index < to; index++)
    {
        result ~= array[index];
    }
    return result;
}

/**
  * Generic decoder for extracting data
  */
string decoder(string name, T...)(size_t index = 0)
{
    static if(T.length != 0)
    {
        auto result = "auto " ~ T[2] ~ " = (cast (" ~ T[0] ~ "[]) (cast (void[]) subArray(" ~ name ~ ", " ~
        to!string(index) ~ ", " ~ to!string(index + T[1]) ~")))[0];\n";
        return result ~ decoder!(name, T[3..$])(index + T[1]);
    }
    else
    {
        return "";
    }
}
