module decoder;

import std.bitmanip;
import std.meta;
import std.format: format;

// Manipulating bits
ubyte getBit(ubyte x, int n) {
    return (x & (1 << n)) >> n;
}

ubyte withBit(ubyte x, int n, ubyte val) {
    if (val) x |= (1 << n);
    else x &= ~(1 << n);
    return x;
}

ubyte setBit(ref ubyte x, int n, ubyte val) {
    x = x.withBit(n, val);
    return x;
}

unittest {
    assert(0.getBit(0) == 0);
    assert(1.getBit(0) == 1);
    assert(2.getBit(0) == 0);
    assert(3.getBit(0) == 1);
    assert(0.getBit(1) == 0);
    assert(1.getBit(1) == 0);
    assert(2.getBit(1) == 1);
    assert(3.getBit(1) == 1);
    assert(0.getBit(2) == 0);
    assert(1.getBit(2) == 0);
    assert(2.getBit(2) == 0);
    assert(3.getBit(2) == 0);
    assert(4.getBit(2) == 1);
    assert(5.getBit(2) == 1);
    assert(6.getBit(2) == 1);
    assert(7.getBit(2) == 1);

    assert(0.withBit(0, 1) == 1);
    assert(1.withBit(0, 0) == 0);
    assert(2.withBit(0, 1) == 3);
    assert(3.withBit(0, 0) == 2);

    foreach (ubyte i; 0..64) {
        ubyte x = i;
        x.setBit(0, 1);
        assert(x == i.withBit(0, 1));
    }
}

/**
 * This decodes a single gray code number
 */
ubyte decodeGray(ubyte bits)(ubyte x) {
    ubyte decoded = 0.withBit(bits - 1, x.getBit(bits - 1));

    foreach_reverse(bit; 0..(bits - 1)) {
        decoded.setBit(bit, decoded.getBit(bit + 1) ^ x.getBit(bit));
    }

    return decoded;
}

unittest {
    assert(decodeGray!4(0) == 0);
    assert(decodeGray!4(1) == 1);
    assert(decodeGray!4(2) == 3);
    assert(decodeGray!4(3) == 2);
    assert(decodeGray!4(4) == 7);
    assert(decodeGray!4(5) == 6);
    assert(decodeGray!4(6) == 4);
    assert(decodeGray!4(7) == 5);
}

/**
 * This is a statically built table that converts
 * bytes in gray code to binary
 */
template grayCodeTable(ubyte bits) {
    static ubyte[1 << bits] grayCodeTable;
    static this() {
        foreach(ubyte i; 0..1 << bits) {
            grayCodeTable[i] = decodeGray!bits(i);
        }
    }
}

/**
 * This decodes a single value from a BitArray.
 * Right now it only does ubytes, because I'm lazy.
 */
T decodeBits(T = ubyte, size_t length)(ref BitArray arr, size_t offset)
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

    return grayCodeTable!length[result];
}

unittest {
    auto arr = BitArray([
            true,  true,  true,  false, true,  false, false, false, false, false, false, false, false, false, false, false,
            false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
            false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
            false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
            false, true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false,
    ]);

    assert(arr.decodeBits!(ubyte, 1)(0) == 1);
    assert(arr.decodeBits!(ubyte, 2)(0) == 2);
    assert(arr.decodeBits!(ubyte, 3)(0) == 5);
    assert(arr.decodeBits!(ubyte, 4)(0) == 5);
    assert(arr.decodeBits!(ubyte, 5)(0) == 26);
    assert(arr.decodeBits!(ubyte, 8)(3) == 3);
    assert(arr.decodeBits!(ubyte, 8)(4) == 1);
    assert(arr.decodeBits!(ubyte, 8)(61) == 32);
    assert(arr.decodeBits!(ubyte, 8)(62) == 16);
    assert(arr.decodeBits!(ubyte, 8)(63) == 8);
    assert(arr.decodeBits!(ubyte, 8)(64) == 4);
    assert(arr.decodeBits!(ubyte, 8)(65) == 2);
}



/**
 * Generic decoder for extracting data
 */
mixin template decoder(string name, string startName, size_t fieldOffset, T...)
{
    import std.conv: to;
    static if(T.length != 0)
    {
        import std.format : format;

        mixin(q{auto %s = decodeBits!(%s, %s)(%s, %s + %s);}.format(T[2], T[0], T[1], name, startName, fieldOffset));
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
    assert(b == 3);
    assert(c == 6);
    assert(d == 9);
}
