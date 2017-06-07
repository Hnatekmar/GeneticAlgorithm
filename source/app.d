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

import Decoder;

import core.simd;
struct GeneticImage
{
    immutable uint w;
    immutable uint h;
    ubyte[] pixels;

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
        pixels = new ubyte[w * h * 4];
    }

    this(Image sfmlImage)
    in
    {
        assert(sfmlImage !is null, "Obrázek nesmí být null!");
    }
    body
    {
        pixels = sfmlImage.getPixelArray().dup;
    }

    Image toSFMLImage()
    {
        Image result = new Image();
        auto castedPixels = cast(ubyte[]) pixels;
        result.create(w, h, castedPixels);
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
            mixin decoder!("genom", "offset", 0,
                        "ubyte", 8, "r",
                        "ubyte", 8, "g",
                        "ubyte", 8, "b",
                        "ubyte", 6, "x",
                        "ubyte", 6, "y",
                        "ubyte", 4, "radius");
            Circle shape;
            shape.color = CircleColor(r, g, b, 255);
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

        auto color = circle.color;
        auto left = circle.x < circle.radius ? 0 : circle.x - circle.radius;
        auto right = min(circle.x + circle.radius + 1, image.w);
        auto top = circle.y < circle.radius ? 0 : circle.y - circle.radius;
        auto bottom = min(circle.y + circle.radius + 1, image.h);

        foreach(x; left..right)
        {
            foreach(y; top..bottom)
            {
                if ((x - circle.x) ^^ 2 + (y - circle.y) ^^ 2 <= circle.radius ^^ 2)
                {
                    auto idx = (y * image.w + x) * 4;

                    auto pixel = image.pixels[idx];
                    if (pixel != 0) image.pixels[idx] = (pixel + color.r) / 2;
                    else image.pixels[idx] = color.r;

                    pixel = image.pixels[idx + 1];
                    if (pixel != 0) image.pixels[idx + 1] = (pixel + color.g) / 2;
                    else image.pixels[idx + 1] = color.g;

                    pixel = image.pixels[idx + 2];
                    if (pixel != 0) image.pixels[idx + 2] = (pixel + color.b) / 2;
                    else image.pixels[idx + 2] = color.b;

                    image.pixels[idx + 3] = 255;
                }
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
        auto fitness = meanSquaredError(source.pixels, destination.getPixelArray());
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
