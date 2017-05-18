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

struct CircleColor
{
    ubyte r, g, b;
}

struct CirclePos(T)
{
    T x, y;
}

struct CircleInfo(T)
{
    ubyte r, g, b;
    T x, y;
    ubyte radius;
    ubyte transparency;
    CircleShape toShape()
    {
        auto shape = new CircleShape(radius);
        shape.position = Vector2f(x, y);
        shape.fillColor = Color(r, g, b, transparency);
        return shape;
    }
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
    return result / a.length;
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
        void[] objects = cast (void[]) genom;
        canvas.clear();
        CircleInfo!ubyte* circles = cast (CircleInfo!ubyte*) objects.ptr;
        auto numberOfCircles = genom.length / (CircleInfo!ubyte.sizeof * 8);
        foreach(index; 0 .. numberOfCircles)
        {
            canvas.draw((*(circles + index)).toShape());
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
	import std.concurrency;
	//core.thread.Mutex lock = new core.thread.Mutex();
	CircleShape[] field;
	auto shapeConvertor = (BitArray genom) =>
	{
	};
    ImageFitness fitness = new ImageFitness("<IMAGE_PATH>");
    const uint NUMBER_OF_CIRCLES = 10;
    shapeConvertor(geneticAlgorithm!(fitness, shapeConvertor)
       ((CircleInfo!ubyte).sizeof * 8 * NUMBER_OF_CIRCLES, 0.0, 40, 0.95).genome);

	short vectorX = 255;
	short vectorY = 255;
	/*
	auto window = new RenderWindow(VideoMode(vectorX,vectorY), "Genetický algoritmus");
	//auto window = new RenderWindow(VideoMode(800,600),"Genetický algoritmus",style,settings);//too hot cpu
	while (window.isOpen())
	{
		Event event;
		while(window.pollEvent(event))
		{
			if(event.type == event.EventType.Closed)
			{
				window.close();
			}
		}
		window.clear(Color.White);
	    lock.lock();
		foreach (circle;field)
		{
			window.draw(circle);
		}
	    lock.unlock();
		window.display();
	}*/
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
