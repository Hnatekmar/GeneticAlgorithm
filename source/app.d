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
CircleShape toShape(ref BitArray genom)
{
        mixin(decoder!("genom", "ubyte", 8, "r",
                                "ubyte", 8, "g",
                                "ubyte", 8, "b",
                                "ubyte", 8, "a",
                                "ubyte", 8, "x",
                                "ubyte", 8, "y",
                                "ubyte", 5, "radius")());
        auto shape = new CircleShape(radius);
        shape.position = Vector2f(x, y);
        shape.fillColor = Color(r, g, b, a);
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
        RenderTexture canvas;
        double bestFitness = double.max;
    }

    this(string path)
    {
        destination = new Image();
        if(!destination.loadFromFile(path))
        {
            throw new ErrnoException("Vstupní obrázek se nepodařilo nahrát!");
        }
        canvas = new RenderTexture();
        auto size = destination.getSize();
        canvas.create(size.x, size.y);
    }

    double opCall(ref BitArray genom)
    {
        canvas.clear();

        foreach(index; 0 .. (genom.length / 53))
        {
            auto circle = subArray(genom, index * 53, index * 53 + 53);
            auto shape = circle.toShape;
            canvas.draw(shape);
        }
        Image source = canvas.getTexture().copyToImage();
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
    ImageFitness fitness = new ImageFitness("/home/martin/IdeaProjects/GeneticAlgorithm/test.png");
    const uint NUMBER_OF_CIRCLES = 3;
    shapeConvertor(geneticAlgorithm!(fitness, shapeConvertor)
       (53 * NUMBER_OF_CIRCLES, 0.0, 10, 0.95).genome);
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
