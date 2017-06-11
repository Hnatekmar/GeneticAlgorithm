import opt;
import genetic;
import std.stdio;
import std.bitmanip;
import dsfml.window;
import dsfml.graphics;
import std.random;
import std.exception;
import std.math;
import util;
import decoder;


struct GeneticImage
{
    uint w;
    uint h;
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
        immutable populationSize = 3 * 8 + 3 * 6;
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

        Circle toShape(ref BitArray genom)
        {
                mixin(decoder.decoder!("genom", "ubyte", 8, "r",
                                        "ubyte", 8, "g",
                                        "ubyte", 8, "b",
                                        "ubyte", 6, "x",
                                        "ubyte", 6, "y",
                                        "ubyte", 6, "radius")());
                Circle shape;
                shape.color = CircleColor(r, g, b, 255);
                shape.x = x;
                shape.y = y;
                shape.radius = radius;
                return shape;
        }
    }

    this(string path)
    {
        destination = new Image();
        if(!destination.loadFromFile(path))
        {
            throw new ErrnoException("Vstupní obrázek se nepodařilo nahrát!");
        }
    }

    import ldc.attributes;
    @fastmath void rasterize(ref GeneticImage image, in Circle[] circles)
    {
        foreach(ref circle; circles)
        {
            auto color = circle.color;
            foreach(x; (circle.x - circle.radius / 2) .. (circle.x + circle.radius / 2))
            {
                foreach(y; (circle.y - circle.radius / 2) .. (circle.y + circle.radius / 2))
                {
                    if(distance(x, y, circle.x, circle.y) <= (circle.radius / 2) &&
                        x >= 0 &&
                        x < image.w &&
                        y >= 0 &&
                        y < image.h)
                    {
                        if(image.pixels[(y * image.w + x) * 4] != 0)
                        {
                        image.pixels[(y * image.w + x) * 4] = (image.pixels[(y * image.w + x) * 4] + color.r) / 2;
                        }
                        else
                        {
                        image.pixels[(y * image.w + x) * 4] = color.r;
                        }

                        if(image.pixels[(y * image.w + x) * 4 + 1] != 0)
                        {
                        image.pixels[(y * image.w + x) * 4 + 1] = (image.pixels[(y * image.w + x) * 4 + 1] + color.g) / 2;
                        }
                        else
                        {
                        image.pixels[(y * image.w + x) * 4 + 1] = color.g;
                        }

                        if(image.pixels[(y * image.w + x) * 4 + 2] != 0)
                        {
                        image.pixels[(y * image.w + x) * 4 + 2] = (image.pixels[(y * image.w + x) * 4 + 2] + color.b) / 2;
                        }
                        else
                        {
                        image.pixels[(y * image.w + x) * 4 + 2] = color.b;
                        }
                        image.pixels[(y * image.w + x) * 4 + 3] = 255;
                    }
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
            auto circle = subArray(genom, index * populationSize, index * populationSize + populationSize);
            auto shape = toShape(circle);
            shapes ~= shape;
        }
        rasterize(source, shapes);
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
    const uint NUMBER_OF_CIRCLES = 500;
    geneticAlgorithm!(fitness, shapeConvertor)((3 * 8 + 2 * 6 + 5) * NUMBER_OF_CIRCLES, 0.0, 50, 0.99);
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
