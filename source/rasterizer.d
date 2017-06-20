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
        import core.simd : __simd, __simd_ib, XMM, ushort8, uint4;
        import dlib.image : color4, Color4, Color4f, alphaOver;
        import std.algorithm : min;

        import decoder : decoder, decodeBits;
        import simdutil : unpacked;

        mixin decoder!("arr", "offset", 0,
                "ubyte", 3, "r",
                "ubyte", 3, "g",
                "ubyte", 3, "b",
                "ubyte", 3, "a",
                "ubyte", 6, "rectX",
                "ubyte", 6, "rectY",
                "ubyte", 6, "rectW",
                "ubyte", 6, "rectH");

        r = r.extendColor;
        g = g.extendColor;
        b = b.extendColor;
        a = a.extendColor;

        int left = rectX;
        int right = min(rectX + rectW, imageW);
        int top = rectY;
        int bottom = min(rectY + rectH, imageH);

        // align x coords to multiples of 4
        int alignedLeft = (left + 3) & ~0x3;
        int alignedRight = right & ~0x3;

        ubyte16 zero = 0;
        ushort8 alphaMult = ushort(a);
        ushort8 negAlphaMult = ushort(255 - a);

        // don't wanna alpha blend the alpha
        alphaMult.unpacked[3] = alphaMult.unpacked[7] = 255;
        negAlphaMult.unpacked[3] = negAlphaMult[7] = 255;

        ushort8 color;
        color.unpacked[] = [r, g, b, 255, r, g, b, 255];

        ushort8 colorPremult = __simd(XMM.PMULLW, color, alphaMult);

        foreach (y; top..bottom)
        {
            auto yIdx = y * imageW / 4;

            for (auto x = alignedLeft; x < alignedRight; x += 4)
            {
                auto idx = yIdx + x / 4;
                ubyte16 pixels = image[idx];

                // extend pixels to 16bit so we can alpha blend
                ushort8 lPixels = __simd(XMM.PUNPCKLBW, pixels, zero);
                ushort8 hPixels = __simd(XMM.PUNPCKHBW, pixels, zero);

                // multiply by the negated alpha
                lPixels = __simd(XMM.PMULLW, lPixels, negAlphaMult);
                hPixels = __simd(XMM.PMULLW, hPixels, negAlphaMult);

                // add the premultiplied color
                lPixels = __simd(XMM.PADDUSW, lPixels, colorPremult);
                hPixels = __simd(XMM.PADDUSW, hPixels, colorPremult);

                // divide by 256 (although this should really be dividing by 255, but eh)
                lPixels = __simd_ib(XMM.PSRLW, lPixels, 8);
                hPixels = __simd_ib(XMM.PSRLW, hPixels, 8);

                // pack it back
                image[idx] = __simd(XMM.PACKUSWB, lPixels, hPixels);
            }
        }

        void withMask(int x, uint4 inMask)
        {
            ubyte16 mask = inMask;
            auto negMask = ~mask;
            foreach (y; top..bottom)
            {
                auto idx = (y * imageW + x) / 4;
                ubyte16 pixels = image[idx];

                // extend pixels to 16bit so we can alpha blend
                ushort8 lPixels = __simd(XMM.PUNPCKLBW, pixels, zero);
                ushort8 hPixels = __simd(XMM.PUNPCKHBW, pixels, zero);

                // multiply by the negated alpha
                lPixels = __simd(XMM.PMULLW, lPixels, negAlphaMult);
                hPixels = __simd(XMM.PMULLW, hPixels, negAlphaMult);

                // add the premultiplied color
                lPixels = __simd(XMM.PADDUSW, lPixels, colorPremult);
                hPixels = __simd(XMM.PADDUSW, hPixels, colorPremult);

                // divide by 256 (although this should really be dividing by 255, but eh)
                lPixels = __simd_ib(XMM.PSRLW, lPixels, 8);
                hPixels = __simd_ib(XMM.PSRLW, hPixels, 8);

                // pakc it back
                ubyte16 packed = __simd(XMM.PACKUSWB, lPixels, hPixels);

                // mask it ad store it
                image[idx] = (negMask & pixels) | (mask & packed);
            }
        }

        uint4 mask = ~0;
        mask[0..alignedLeft - left][] = 0;
        withMask(left, mask);

        mask[] = 0;
        mask[0..right - alignedRight][] = ~0;
    }
}
