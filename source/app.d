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

class ImageFitness
{
    private
    {
        immutable populationSize = 5 * 8 + 8;
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
                mixin(decoder!("genom", "ubyte", 8, "r",
                                        "ubyte", 8, "g",
                                        "ubyte", 8, "b",
                                        "ubyte", 8, "x",
                                        "ubyte", 8, "y",
                                        "ushort", 8, "radius")());
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

    void rasterize(Image image, ref Circle circle)
    {
        auto size = image.getSize();
        foreach(x; (circle.x - circle.radius / 2) .. (circle.x + circle.radius / 2))
        {
            foreach(y; (circle.y - circle.radius / 2) .. (circle.y + circle.radius / 2))
            {
                if(distance(x, y, circle.x, circle.y) <= circle.radius / 2 &&
                    x >= 0 &&
                    y >= 0 &&
                    x < size.x &&
                    y < size.y)
                {
                    auto color = circle.color;
                    auto pixelColor = image.getPixel(cast(uint) x, cast(uint) y);
                    image.setPixel(cast(uint) x, cast(uint) y, Color(
                                  cast(uint) (pixelColor.r + color.r) / 2,
                                  cast(uint) (pixelColor.g + color.g) / 2,
                                  cast(uint) (pixelColor.b + color.b) / 2,
                                  color.a));
                }
            }
        }
    }

    double opCall(ref BitArray genom)
    {
        immutable auto size = destination.getSize();
        Image source = new Image();
        source.create(size.x, size.y, Color(0, 0, 0));
        foreach(index; 0 .. (genom.length / populationSize))
        {
            auto circle = subArray(genom, index * populationSize, index * populationSize + populationSize);
            auto shape = toShape(circle);
            rasterize(source, shape);
        }
        auto fitness = meanSquaredError(source.getPixelArray(), destination.getPixelArray());
        if(fitness < bestFitness)
        {
            source.saveToFile("last.png");
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
    ImageFitness fitness = new ImageFitness("<IMAGE PATH>");
    const uint NUMBER_OF_CIRCLES = 100;
    geneticAlgorithm!(fitness, shapeConvertor)(45 * NUMBER_OF_CIRCLES, 0.0, 25, 0.85);
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
