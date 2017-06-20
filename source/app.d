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
import std.concurrency;

class ImageFitness
{
    immutable populationSize = 32 + 4 * 6;
    private
    {
        SuperImage destination;
        Tid threadId;
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

    this(string path, Tid id)
    {
        threadId = id;
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
            send(threadId, cast (immutable SuperImage) source);
            source.saveImage("last.png");
            bestFitness = fitness;
        }
        return fitness;
    }
}


sfmlImage.Image dlibImageToSfmlImage(SuperImage img)
{
    auto im = dlib.image.convert!(ImageRGBA8)(img);
    auto image = new sfmlImage.Image();
    auto pixels = im.data;
    image.create(img.width, img.height, pixels);
    return image;
}

void loadImageIntoSprite(SuperImage img, ref Sprite sprite)
{
    if(sprite is null) sprite = new Sprite;
    sfmlImage.Image sfmlImg = img.dlibImageToSfmlImage;
    auto texture = new Texture;
    texture.loadFromImage(sfmlImg);
    sprite.setTexture(texture, true);
}

void gaThread(in Options options,Tid someId)
{
    ImageFitness fitness = new ImageFitness(options.input, someId);
    geneticAlgorithm!fitness(fitness.populationSize * options.shapeCount, 0.0, 50, options.mutation, options.countEpoch, options.forever);
}

import core.sync.mutex;

void draw(in Options options)
{
    auto threadId = spawn(&gaThread, options,thisTid);
    ushort vectorX = 64;
    ushort vectorY = 64;
    core.sync.mutex.Mutex mutex = new core.sync.mutex.Mutex();
    Sprite sprite; //= new Sprite;
    auto window = new RenderWindow(
            VideoMode(vectorX, vectorY),
            "Genetický algoritmus"
            );

    while (window.isOpen())
    {
        receiveTimeout(100.msecs, (SuperImage img)
                {
                loadImageIntoSprite(img, sprite);
                });
        Event event;
        while(window.pollEvent(event))
        {
            if(event.type == event.EventType.Closed)
            {
                window.close();
            }
        }
        window.clear(Color.White);
        mutex.lock();
        window.draw(sprite);
        mutex.unlock();
        window.display();
    }
}

void main(string[] argv)
{
    auto data = getOptions(argv);
    draw(data);
}
