module decoder;

import std.bitmanip;
import std.meta;
import std.format: format;

/**
* Splits BitArray into smaller BitArray
*/
BitArray subArray(ref BitArray array, size_t fromBit, size_t toBit)
in
{
    assert(fromBit < toBit, "From has to be smaller than to and they cannot equal");
}
body
{
	enum sizetBits = size_t.sizeof * 8;
    const bitSize = toBit - fromBit;
    const from = fromBit / sizetBits;
    const to = (toBit + sizetBits - 1) / sizetBits;
    auto bits = (cast(size_t[]) array)[from .. to].dup;
	const shift = fromBit - from * sizetBits;
	assert(shift < 64);
	shiftArr(bits, shift, toBit - from * sizetBits);
	return BitArray(bits, bitSize);
}

void shiftArr(size_t[] arr, size_t n, size_t totalBits)
in
{
	assert(n < 64);
}
body
{
	if (n == 0)
	{
		return;
	}

	enum sizetBits = size_t.sizeof * 8;

	foreach (i; 0..arr.length - 1)
	{
		arr[i] = (arr[i] >> n) | ((arr[i + 1] & ((size_t(1) << n) - 1)) << (sizetBits - n));
	}

	const remainingBits = totalBits % sizetBits;
	const mask = remainingBits ? (size_t(1) << remainingBits) - 1 : ~0;
	arr[$ - 1] = (arr[$ - 1] & mask) >> n;
}

unittest
{
	size_t[] arr = [1024, 1024, 1024, 1024];
	shiftArr(arr, 1, 4 * size_t.sizeof * 8);
	assert(arr == [512, 512, 512, 512]);
}

/**
* Generic decoder for extracting data
*/
string decoder(string name, T...)(size_t index = 0)
{
    import std.conv: to;
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

unittest
{
    import std.range;
    import std.random;
    import std.algorithm;
    import std.stdio;
    foreach(n; 0 .. 250)
    {
        bool[] bits = iota(n).map!(x => uniform(0, 2) == 0).array;
        BitArray array = BitArray(bits);
        foreach(from; 0 .. bits.length)
        {
            foreach(to; from + 1 .. bits.length)
            {
                auto bitSlice = bits[from .. to];
                auto expectedSlice = cast(size_t[])BitArray(bitSlice);
                auto slice = cast(size_t[])array.subArray(from, to);
                assert(expectedSlice == slice, format!"%s != %s u %s[%s .. %s] == %s"(expectedSlice, slice, bits,
                from, to, bits[from .. to]));
            }
        }
    }
}
