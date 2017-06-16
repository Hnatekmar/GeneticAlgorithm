import opt;
import genetic;
import std.stdio;
import std.bitmanip;
import std.random;
import std.exception;
import std.math;
import util;
import decoder;
import dlib.image;
import dlib.image.color: color4;
import std.file;
import std.conv;

class ImageFitness
{
    immutable populationSize = 32 + 4 * 6;
    private
    {
        SuperImage destination;
        double bestFitness = double.max;

        struct Rect
        {
            Color4f color;
            ubyte x, y;
            ushort width, heigth;
        }

        Rect toShape(ref BitArray genom)
        {
                mixin(decoder.decoder!("genom",
                                        "int",  32, "color",
                                        "ubyte", 6, "x",
                                        "ubyte", 6, "y",
                                        "ubyte", 6, "width",
																				"ubyte", 6, "heigth")());
                Rect shape;
                shape.color = color4(color);
                shape.x = x;
                shape.y = y;
								shape.width = width;
								shape.heigth = heigth;
                return shape;
        }
    }

    this(string path)
    {
        destination = loadImage(path);
    }

    void rasterize(ref SuperImage image, in Rect[] rects)
    {
        foreach(ref rect; rects)
        {
            auto color = rect.color;
            foreach(x; (rect.x) .. (rect.x + rect.width))
            {
                foreach(y; (rect.y) .. (rect.y + rect.heigth))
                {
                    if( x >= 0 &&
                        x < image.width &&
                        y >= 0 &&
                        y < image.height)
                    {
                        image[x, y] = alphaOver(image[x, y], color);
                    }
                }
            }
        }
    }

    double opCall(ref BitArray genom)
    {
        SuperImage source = image(destination.width, destination.height);
        Rect[] shapes;
        foreach(index; 0 .. (genom.length / populationSize))
        {
            auto circle = subArray(genom, index * populationSize, index * populationSize + populationSize);
            auto shape = toShape(circle);
            shapes ~= shape;
        }
        rasterize(source, shapes);
        auto fitness = meanSquaredError(source.data, destination.data);
        if(fitness < bestFitness)
        {
            source.saveImage("last.png");
            bestFitness = fitness;
        }
        return fitness;
    }
}

void draw(string input,float mutation = 0.99)
{
	string pwd = getcwd();
	if ( (pwd ~ "/" ~ input).exists){
    ImageFitness fitness = new ImageFitness(input);
    const uint NUMBER_OF_RECTANGLES = 20;
    geneticAlgorithm!(fitness)(fitness.populationSize * NUMBER_OF_RECTANGLES, 0.0, 50, mutation);
	}else{
		writeln("ERROR: File " ~ pwd ~ "/" ~ input ~ " not found.");
	}
}

void main(string[] argv)
{
    if (argv.length > 1)
    {
			auto data = getOptions(argv);
			draw(data.input, data.probability);
    }
}
