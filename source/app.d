import opt;
import genetic;
import std.stdio;
import string_gen;
import std.bitmanip;
import dsfml.window;
import dsfml.graphics;
import std.random;
import std.exception;
import std.traits;
import std.math;

import Decoder;

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

double distance(uint x0, uint y0, uint x1, uint y1)
{
    return sqrt(cast(double)((x0 - x1) ^^ 2 + (y0 - y1) ^^ 2));
}

Circle toShape(ref BitArray genom)
{
        mixin(decoder!("genom", "ubyte", 8, "r",
                                "ubyte", 8, "g",
                                "ubyte", 8, "b",
                                "ubyte", 8, "x",
                                "ubyte", 8, "y",
                                "ushort", 9, "radius")());
        Circle shape;
        shape.color = CircleColor(r, g, b, 255);
        shape.x = x;
        shape.y = y;
        shape.radius = radius;
        return shape;
}

double meanSquaredError(T)(const T[] a, const T[] b)
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
    foreach(index;0 .. a.length)
    {
        result += pow(a[index] - b[index], 2.0);
    }
    return result;
}

class ImageFitness
{
    private
    {
        Image destination;
        double bestFitness = double.max;
    }

    this(string path)
    {
        destination = new Image();
        if(!destination.loadFromFile(path))
        {
            throw new ErrnoException("Vstupní obrázek se nepodařilo nahrát!");
        }
    }

    void rasterize(Image image, Circle circle)
    {
        auto size = image.getSize();
        foreach(x; (circle.x - circle.radius / 2) .. (circle.x + circle.radius / 2))
        {
            foreach(y; (circle.y - circle.radius / 2) .. (circle.y + circle.radius / 2))
            {
                if(distance(x, y, circle.x, circle.y) <= circle.radius / 2 && x >= 0 && y >= 0 && x < size.x && y <
                size.y)
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
        foreach(index; 0 .. (genom.length / 45))
        {
            auto circle = subArray(genom, index * 45, index * 45 + 45);
            auto shape = circle.toShape;
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
	import core.thread;
	CircleShape[] field;
	auto shapeConvertor = (BitArray genom) =>
	{
	};
    ImageFitness fitness = new ImageFitness("/home/martin/IdeaProjects/GeneticAlgorithm/plt-logo-red-diffuse.png");
    const uint NUMBER_OF_CIRCLES = 100;
    shapeConvertor(geneticAlgorithm!(fitness, shapeConvertor)
       (45 * NUMBER_OF_CIRCLES, 0.0, 25, 0.85).genome);
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
