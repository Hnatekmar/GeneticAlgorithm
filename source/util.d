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
double meanSquaredError(T)(const T[] a, const T[] b)
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
    foreach(index;0 .. a.length)
    {
        result += pow(a[index] - b[index], 2.0);
    }
    return result / a.length;
}

/**
 * Computes distance between two points in 2D euclidean space
 */
double distance(int x0, int y0, int x1, int y1)
{
    return sqrt(cast(double)((x0 - x1) ^^ 2 + (y0 - y1) ^^ 2));
}
