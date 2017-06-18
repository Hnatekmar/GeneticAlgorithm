module util;

import std.traits;
import std.math;

/**
* Calculates meanSquared error from two arrays
* Example:
* ---
* int[] a = [0, 1, 2];
* int[] b = [0, 1, 3];
* meanSquaredError(a, b).writeln;
* ---
*/
pure double meanSquaredError(T)(in T[] a, in T[] b)
    if(isIntegral!T)
in
{
    assert(a.length == b.length, "Pole musí být stejné delky");
}
out(result)
{
    assert(result >= 0.0, "Výsledek least squares je vždy kladný!");
}
body
{
    double result = 0.0;
    foreach(size_t index; 0 .. a.length)
    {
        result += (a[index] - b[index]) ^^ 2;
    }
    return result / a.length;
}
