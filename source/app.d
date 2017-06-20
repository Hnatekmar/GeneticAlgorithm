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
import dsfml.window;
import dsfml.graphics;
import sfmlImage = dsfml.graphics.image;

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
            ushort width, height;
        }

        Rect toShape(ref BitArray genom)
        {
            mixin(decoder.decoder!("genom",
                        "int",  32, "color",
                        "ubyte", 6, "x",
                        "ubyte", 6, "y",
                        "ubyte", 6, "width",
                        "ubyte", 6, "height")());
            Rect shape;
            shape.color = color4(color);
            shape.x = x;
            shape.y = y;
            shape.width = width;
            shape.height = height;
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
            foreach(x; rect.x .. (rect.x + rect.width))
            {
                foreach(y; rect.y .. (rect.y + rect.height))
                {
                    if( x >= 0 &&
                        x < image.width &&
                        y >= 0 &&
                        y < image.height)
                    {
                        image[x, y] = alphaOver(image[x, y], rect.color);
                    }
                }
            }
        }
    }

    sfmlImage.Image convertSImage(SuperImage img)
    {
        auto im = dlib.image.convert!(ImageRGBA8)(img);
        auto image = new sfmlImage.Image();
        auto pixels = im.data;
        image.create(img.width, img.height, pixels);
        return image;
    }

    void printWindow(SuperImage inImage)
    {
        ushort vectorX = 64;
        ushort vectorY = 64;
        auto sprite = new Sprite;
        auto texture = new Texture;
        auto convImage = convertSImage(inImage);
        auto window = new RenderWindow(
                VideoMode(vectorX, vectorY),
                "Genetický algoritmus"
                );
        texture.loadFromImage(convImage);
        sprite.setTexture(texture, true);

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
            window.draw(sprite);
            window.display();
        }
    }

    double opCall(ref BitArray genom)
    {
        SuperImage source = image(destination.width, destination.height);
        Rect[] shapes;
        size_t numberOfShapesInPopulation = genom.length / populationSize;
        shapes.reserve(numberOfShapesInPopulation);
        foreach(index; 0 .. numberOfShapesInPopulation)
        {
            auto circle = subArray(genom, index * populationSize, index * populationSize + populationSize);
            shapes ~= toShape(circle);
        }
        rasterize(source, shapes);
        auto fitness = meanSquaredError(source.data, destination.data);
        if(fitness < bestFitness)
        {
            source.saveImage("last.png");
            printWindow(source);
            bestFitness = fitness;
        }
        return fitness;
    }
}

void draw(in Options options)
{
    ImageFitness fitness = new ImageFitness(options.input);
    geneticAlgorithm!(fitness)(fitness.populationSize * options.shapeCount, 0.0, 50, options.mutation, options
    .countEpoch,
    options.forever);
}

void main(string[] argv)
{
    auto data = getOptions(argv);
    draw(data);
}
