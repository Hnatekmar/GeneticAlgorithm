import opt;
import genetic;
import std.bitmanip;
import util;
import dsfml.graphics;
import dsfml.graphics.image;
import std.concurrency;
import dlib.image.color: color4;
import dlib.image;
import type;
import draw;
import decoder;

class ImageFitness
{
    enum populationSize = 32 + 4 * 6;
    private
    {
        SuperImage destination;
        Tid threadId;
        double bestFitness = double.max;
        draw.Rect toShape(ref BitArray genom)
        {
            mixin(decoder.decoder!("genom",
                        "int",  32, "color",
                        "ubyte", 6, "x",
                        "ubyte", 6, "y",
                        "ubyte", 6, "width",
                        "ubyte", 6, "height")());
            draw.Rect shape;
            shape.color = color4(color);
            shape.x = x;
            shape.y = y;
            shape.width = width;
            shape.height = height;
            return shape;
        }
    }

    this(string path, Tid id)
    {
        threadId = id;
        destination = loadImage(path);
    }

    double opCall(ref BitArray genom)
    {
        SuperImage source = image(destination.width, destination.height);
        draw.Rect[] shapes;
        size_t numberOfShapesInPopulation = genom.length / populationSize;
        shapes.reserve(numberOfShapesInPopulation);
        foreach(index; 0 .. numberOfShapesInPopulation)
        {
            auto circle = subArray(genom, index * populationSize, index * populationSize + populationSize);
            shapes ~= toShape(circle);
        }
        rasterizeRectangles(source, shapes);
        auto fitness = meanSquaredError(source.data, destination.data);
        if(fitness < bestFitness)
        {
            send(threadId, cast(shared) dlibImageToSfmlImage(source));
            source.saveImage("last.png");
            bestFitness = fitness;
        }
        return fitness;
    }
}

void gaThread(in Options options, Tid someId)
{
    ImageFitness fitness = new ImageFitness(options.input, someId);
    geneticAlgorithm!fitness(fitness.populationSize * options.shapeCount, 0.0, 50, options.mutation, options.countEpoch, options.forever);
}

void drawingThread(in Options options)
{
    import dsfml.window;
    auto threadId = spawn(&gaThread, options, thisTid);
    ushort vectorX = 64;
    ushort vectorY = 64;
    Sprite sprite;
    auto window = new RenderWindow(
            VideoMode(vectorX, vectorY),
            "Genetický algoritmus"
            );

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
        receiveTimeout(100.msecs, (shared SfmlImage img)
                {
                    loadImageIntoSprite(cast(SfmlImage) img, sprite);
                });
        window.clear(Color.White);
        if(sprite !is null) window.draw(sprite);
        window.display();
    }
}

void main(string[] argv)
{
    auto data = getOptions(argv);
    drawingThread(data);
}
