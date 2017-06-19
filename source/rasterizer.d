module rasterizer;

ubyte extendColor(ubyte x)
{
    return cast(ubyte) ((x << 5) | (x << 2) | (x >> 1));
}

struct CircleRasterizer
{
    import std.bitmanip : BitArray;
    import core.simd : ubyte16;

    enum shapeBits = 3 * 3 + 2 * 6 + 4;

    static void rasterizeShape(ubyte16[] image, size_t imageW, size_t imageH, ref BitArray arr, size_t offset)
    {
        import std.algorithm : min, max;
        import decoder : decoder, decodeBits;
        import core.simd : __simd, XMM, uint4;
        import simdutil : unpacked;

        mixin decoder!("arr", "offset", 0,
                "ubyte", 3, "r",
                "ubyte", 3, "g",
                "ubyte", 3, "b",
                "ubyte", 6, "circleX",
                "ubyte", 6, "circleY",
                "ubyte", 4, "radius");

        r = extendColor(r);
        g = extendColor(g);
        b = extendColor(b);

        auto left = max(0, circleX - radius);
        auto right = min(circleX + radius + 1, imageW);
        auto top = max(0, circleY - radius);
        auto bottom = min(circleY + radius + 1, imageH);

        // Make sure the x positions are nicely aligned
        left = left & ~3;
        right = (right + 3) & ~3;

        ubyte16 color;
        color.unpacked[] = [r, g, b, 255, r, g, b, 255, r, g, b, 255, r, g, b, 255];

        uint4 radSquared = radius ^^ 2;
        ubyte16 zero = 0;

        foreach(y; top..bottom)
        {
            // A lot of the following will go negative even though it's unsigned,
            // but ultimately it doesn't matter, because we'll be squaring it anyway.
            uint4 xPixel = [0, 1, 2, 3];
            xPixel += left - circleX;
            uint4 ySquared = (y - circleY) ^^ 2;

            ubyte16 alphaMask = [0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255];

            auto yIdx = y * imageW / 4;

            for (auto x = left; x < right; x += 4, xPixel += 4)
            {
                auto idx = yIdx + x / 4;
                ubyte16 pixels = image[idx];

                // (x - circleX) ^^ 2
                uint4 xSquared = __simd(XMM.PMULLD, xPixel, xPixel);

                // all ones for kept pixels and vice versa
                ubyte16 keepMask = __simd(XMM.PCMPGTD, xSquared + ySquared, radSquared);

                // all ones for pexes written directly, zeros for pexes mixed
                ubyte16 directMask = __simd(XMM.PCMPEQB, pixels, zero);

                // color of the circle mixed with the previous color
                ubyte16 mixedColor = __simd(XMM.PAVGB, color, pixels);

                // color as if the circle were present
                ubyte16 circleColor = (directMask & color) | (~directMask & mixedColor);

                // final color
                ubyte16 finalColor = (keepMask & pixels) | (~keepMask & circleColor);

                image[idx] = finalColor;
            }
        }
    }
}

struct RectangleRasterizer
{
    import std.bitmanip : BitArray;
    import core.simd : ubyte16;

    enum shapeBits = 4 * 3 + 4 * 6;

    static void rasterizeShape(ubyte16[] image, size_t imageW, size_t imageH, ref BitArray arr, size_t offset)
    {
        import dlib.image : color4, Color4, Color4f, alphaOver;
        import decoder : decoder, decodeBits;

        mixin decoder!("arr", "offset", 0,
                "ubyte", 3, "r",
                "ubyte", 3, "g",
                "ubyte", 3, "b",
                "ubyte", 3, "a",
                "ubyte", 6, "rectX",
                "ubyte", 6, "rectY",
                "ubyte", 6, "rectW",
                "ubyte", 6, "rectH");

        auto color = color4((r.extendColor << 24) | (g.extendColor << 16) | (b.extendColor << 8) | a.extendColor);
        auto pixels = cast(ubyte[]) image;
        foreach (x; rectX .. (rectX + rectW))
        {
            foreach (y; rectY .. (rectY + rectH))
            {
                if (x >= 0 &&
                        x < imageW &&
                        y >= 0 &&
                        y < imageH)
                {
                    auto idx = (y * imageW + x) * 4;
                    auto pixel = Color4f(Color4(pixels[idx], pixels[idx + 1], pixels[idx + 2], pixels[idx + 3]), 8);
                    auto newPixel = alphaOver(pixel, color).convert(8);
                    pixels[idx] = cast(ubyte) newPixel[0];
                    pixels[idx + 1] = cast(ubyte) newPixel[1];
                    pixels[idx + 2] = cast(ubyte) newPixel[2];
                    pixels[idx + 3] = cast(ubyte) newPixel[3];
                }
            }
        }
    }
}
