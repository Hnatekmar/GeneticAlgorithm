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

class ImageFitness
{
    immutable populationSize = 32 + 3 * 6;
    private
    {
        SuperImage destination;
        double bestFitness = double.max;

        struct Circle
        {
            Color4f color;
            ubyte x, y;
            ushort radius;
        }

        Circle toShape(ref BitArray genom)
        {
                mixin(decoder.decoder!("genom",
                                        "int",  32, "color",
                                        "ubyte", 6, "x",
                                        "ubyte", 6, "y",
                                        "ubyte", 6, "radius")());
                Circle shape;
                shape.color = color4(color);
                shape.x = x;
                shape.y = y;
                shape.radius = radius;
                return shape;
        }
    }

    this(string path)
    {
        destination = loadImage(path);
    }

    void rasterize(ref SuperImage image, in Circle[] circles)
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
        Circle[] shapes;
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


void draw()
{
    ImageFitness fitness = new ImageFitness("mona4.jpg");
    const uint NUMBER_OF_CIRCLES = 10;
    geneticAlgorithm!(fitness)(fitness.populationSize * NUMBER_OF_CIRCLES, 0.0, 50, 0.99);
}

void main(string[] argv)
{
    if (argv.length > 1)
    {
        getoptions(argv);
    }
    draw();
}
