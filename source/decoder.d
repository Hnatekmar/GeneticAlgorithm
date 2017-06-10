module decoder;

import std.bitmanip;
import std.range;
import std.meta;
import std.conv;

T decodeBits(T)(ref BitArray arr, size_t offset, size_t length)
in {
    assert(length <= T.sizeof * 8, "Result of decodeBits must fit in the result type");
}
body {
    import std.algorithm : min;

    const sizetBits = size_t.sizeof * 8;
    const data = (cast(size_t[]) arr)[offset / sizetBits..$];
    const bitOffset = offset % sizetBits;
    const firstAvailable = sizetBits - bitOffset;
    const firstNumBits = min(length, firstAvailable);

    const firstMask = (1 << firstNumBits) - 1;
    auto result = (data[0] >> bitOffset) & firstMask;

    if (firstAvailable < length) {
        // not enough bits available in the first size_t, we need one more
        const secondNumBits = length - firstAvailable;
        const secondMask = (1 << secondNumBits) - 1;
        result |= (data[1] & secondMask) << firstAvailable;
    }

    return cast(T) result;
}

unittest {
    auto arr = BitArray([
            true,  true,  true,  false, true,  false, false, false, false, false, false, false, false, false, false, false,
            false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
            false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
            false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
            false, true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false,
    ]);

    assert(arr.decodeBits!ubyte(0, 1) == 1);
    assert(arr.decodeBits!ubyte(0, 2) == 3);
    assert(arr.decodeBits!ubyte(0, 3) == 7);
    assert(arr.decodeBits!ubyte(0, 4) == 7);
    assert(arr.decodeBits!ubyte(0, 5) == 23);
    assert(arr.decodeBits!ubyte(3, 8) == 2);
    assert(arr.decodeBits!ubyte(4, 8) == 1);
    assert(arr.decodeBits!ubyte(61, 8) == 48);
    assert(arr.decodeBits!ubyte(62, 8) == 24);
    assert(arr.decodeBits!ubyte(63, 8) == 12);
    assert(arr.decodeBits!ubyte(64, 8) == 6);
    assert(arr.decodeBits!ubyte(65, 8) == 3);
}

/**
 * Generic decoder for extracting data
 */
mixin template decoder(string name, string startName, size_t fieldOffset, T...)
{
    static if(T.length != 0)
    {
        import std.format : format;

        mixin(q{auto %s = decodeBits!%s(%s, %s + %s, %s);}.format(T[2], T[0], name, startName, fieldOffset, T[1]));
        mixin decoder!(name, startName, fieldOffset + T[1], T[3..$]);
    }
}

unittest {
    auto arr = BitArray([true, false, true, true, false, true, true, false, true, true]);

    mixin decoder!("arr", "0", 0,
            "ubyte", 1, "a",
            "ubyte", 2, "b",
            "ubyte", 3, "c",
            "ubyte", 4, "d");

    assert(a == 1);
    assert(b == 2);
    assert(c == 5);
    assert(d == 13);
}
