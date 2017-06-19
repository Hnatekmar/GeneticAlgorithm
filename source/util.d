module util;

import std.bitmanip : BitArray;
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

/**
 * Takes the first n bits from arrA and length - n bits from arrB and smashes
 * them together.
 */
pure BitArray mergeBitArray(ulong n, ref BitArray arrA, ref BitArray arrB) {
    const sizetBits = size_t.sizeof * 8;
    const splitWord = n / sizetBits;

    auto a = cast(size_t[]) arrA;
    auto b = cast(size_t[]) arrB;

    auto newArr = a[0..splitWord] ~ b[splitWord..$];
    const aMask = (size_t(1) << (n % sizetBits)) - 1;
    newArr[splitWord] = (a[splitWord] & aMask) | (b[splitWord] & ~aMask);
    return BitArray(newArr, arrA.length);
}

unittest {
    import std.array : array;
    import std.format : format;
    import std.range : chain, repeat;

    auto a = BitArray(repeat(true, 80).array);
    auto b = BitArray(repeat(false, 80).array);

    void test(ulong n) {
        const expected = BitArray(repeat(true, n).chain(repeat(false, a.length - n)).array);
        const merged = mergeBitArray(n, a, b);
        assert(merged == expected, "Expected %s trues, got %s".format(n, merged));
    }

    test(0);
    test(2);
    test(31);
    test(32);
    test(63);
    test(64);
    test(65);
}
