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

enum rectangleGenomSize = 32 + 4 * 6;
draw.Rect toRectangle(ref BitArray genom)
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

enum circleGenomSize = 32 + 2 * 6 + 5;
draw.Circle toCircle(ref BitArray genom)
{
    mixin(decoder.decoder!("genom",
                "int",  32, "color",
                "ubyte", 6, "x",
                "ubyte", 6, "y",
                "ushort", 5, "radius")());
    draw.Circle shape;
    shape.color = color4(color);
    shape.x = x;
    shape.y = y;
    shape.radius = radius;
    return shape;
}

class ImageFitness(alias toShape, alias rasterizer, size_t genomSize)
{
    private
    {
        SuperImage destination;
        Tid threadId;
        double bestFitness = double.max;
    }

    this(string path, Tid id)
    {
        threadId = id;
        destination = loadImage(path);
    }

    double opCall(ref BitArray genom)
    {
        import std.traits: ReturnType;
        SuperImage source = image(destination.width, destination.height);
        ReturnType!toShape[] shapes;
        size_t numberOfShapesInPopulation = genom.length / genomSize;
        shapes.reserve(numberOfShapesInPopulation);
        foreach(index; 0 .. numberOfShapesInPopulation)
        {
            auto shape = subArray(genom, index * genomSize, index * genomSize + genomSize);
            shapes ~= toShape(shape);
        }
        rasterizer(source, shapes);
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

void gaCircle(in Options options, Tid someId)
{
            auto fitness = new ImageFitness!(toCircle, rasterizeCircles, circleGenomSize)(options.input, someId);
            geneticAlgorithm!fitness(circleGenomSize * options.shapeCount, 0.0, 50, options.mutation, options.maxEpoch,
            options.forever);
}

void gaRectangle(in Options options, Tid someId)
{
    auto fitness = new ImageFitness!(toRectangle, rasterizeRectangles, rectangleGenomSize)(options.input,
    someId);
    geneticAlgorithm!fitness(rectangleGenomSize * options.shapeCount, 0.0, 50, options.mutation, options.maxEpoch,
    options.forever);
}

void drawingThread(in Options options)
{
    import dsfml.window;

    Tid threadId;
    if(options.type == ShapeType.circle)
    {
        threadId = spawn(&gaCircle, options, thisTid);
    }
    if(options.type == ShapeType.rectangle)
    {
        threadId = spawn(&gaRectangle, options, thisTid);
    }
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
