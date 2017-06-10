import opt;
import genetic;
import std.stdio;
import string_gen;
import std.bitmanip;
import dsfml.window;
import dsfml.graphics;
import std.random;
import std.exception;
import std.math;
import util;
import simdutil;

import Decoder;

import core.simd;
struct GeneticImage
{
    immutable uint w;
    immutable uint h;
    ubyte16[] pixels;

    this(uint width, uint height)
    in
    {
        assert(w % 4 == 0, "Šířka musí být dělitelná 4!");
        assert(h % 4 == 0, "Výška musí být dělitelná 4!");
    }
    body
    {
        w = width;
        h = height;
        pixels = new ubyte16[w * h / 4];
        foreach(pixelPack; pixels) {
            pixelPack = [0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255];
        }
    }

    this(Image sfmlImage)
    in
    {
        assert(sfmlImage !is null, "Obrázek nesmí být null!");
    }
    body
    {
        pixels.unpacked[] = sfmlImage.getPixelArray()[];
    }

    Image toSFMLImage()
    {
        Image result = new Image();
        auto unpackedPixels = pixels.unpacked;
        result.create(w, h, unpackedPixels);
        return result;
    }
}

class ImageFitness
{
    private
    {
        Image destination;
        double bestFitness = double.max;

        struct CircleColor
        {
            ubyte r, g, b, a;
        }

        struct Circle
        {
            CircleColor color;
            ubyte x, y;
            ushort radius;
        }

        Circle toShape(ref BitArray genom, size_t offset)
        {
            ubyte extendColor(ubyte x) {
                import std.conv : to;
                return cast(ubyte) ((x << 5) | (x << 2) | (x >> 1));
            }
            mixin decoder!("genom", "offset", 0,
                        "ubyte", 3, "r",
                        "ubyte", 3, "g",
                        "ubyte", 3, "b",
                        "ubyte", 6, "x",
                        "ubyte", 6, "y",
                        "ubyte", 4, "radius");
            Circle shape;
            shape.color = CircleColor(extendColor(r), extendColor(g), extendColor(b), 255);
            shape.x = x;
            shape.y = y;
            shape.radius = radius;
            return shape;
        }
    }

    static immutable populationSize = 3 * 8 + 2 * 6 + 4;

    this(string path)
    {
        destination = new Image();
        if(!destination.loadFromFile(path))
        {
            throw new ErrnoException("Vstupní obrázek se nepodařilo nahrát!");
        }
    }

    void rasterizeCircle(ref GeneticImage image, in Circle circle)
    {
        import std.algorithm : min;

        auto left = circle.x < circle.radius ? 0 : circle.x - circle.radius;
        auto right = min(circle.x + circle.radius + 1, image.w);
        auto top = circle.y < circle.radius ? 0 : circle.y - circle.radius;
        auto bottom = min(circle.y + circle.radius + 1, image.h);

        // Make sure the x positions are nicely aligned
        left = left & ~3;
        right = (right + 3) & ~3;

        ubyte16 color;
        color.unpacked[] = [circle.color.r, circle.color.g, circle.color.b, 255, circle.color.r, circle.color.g, circle.color.b, 255, circle.color.r, circle.color.g, circle.color.b, 255, circle.color.r, circle.color.g, circle.color.b, 255];

        uint4 radSquared = circle.radius ^^ 2;
        ubyte16 zero = 0;

        foreach(y; top..bottom)
        {
            // A lot of the following will go negative even though it's unsigned,
            // but ultimately it doesn't matter, because we'll be squaring it anyway.
            uint4 xPixel = [0, 1, 2, 3];
            xPixel += left - circle.x;
            uint4 ySquared = (y - circle.y) ^^ 2;

            ubyte16 alphaMask = [0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255];

            auto yIdx = y * image.w / 4;

            for (auto x = left; x < right; x += 4, xPixel += 4)
            {
                auto idx = yIdx + x / 4;
                ubyte16 pixels = image.pixels[idx];

                // (x - circle.x) ^^ 2
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

                image.pixels[idx] = finalColor;
            }
        }
    }

    double opCall(ref BitArray genom)
    {
        immutable auto size = destination.getSize();
        GeneticImage source = GeneticImage(size.x, size.y);
        Circle[] shapes;
        foreach(index; 0 .. (genom.length / populationSize))
        {
            auto shape = toShape(genom, index * populationSize);
            rasterizeCircle(source, shape);
        }
        auto fitness = meanSquaredError(source.pixels.unpacked, destination.getPixelArray());
        if(fitness < bestFitness)
        {
            source.toSFMLImage.saveToFile("last.png");
            bestFitness = fitness;
        }
        return fitness;
    }
}


void draw()
{
    auto shapeConvertor = (BitArray genom) =>
    {
    };
    ImageFitness fitness = new ImageFitness("mona.jpeg");
    const uint NUMBER_OF_CIRCLES = 250;
    geneticAlgorithm!(fitness, shapeConvertor)(ImageFitness.populationSize * NUMBER_OF_CIRCLES, 0.0, 50, 0.99);
}

void main(string[] argv)
{
    if (argv.length > 1)
    {
        getoptions(argv);
    }
    try
    {
        draw();
    }
    catch(ErrnoException err)
    {
        err.msg.writeln;
    }
}
