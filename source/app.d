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

import dlib.image : ImageRGBA8, PixelFormat;

class AlignedImage: ImageRGBA8
{
    this(uint w, uint h)
    {
        super(w, h);
    }

    override protected void allocateData()
    {
        import core.simd : ubyte16;

        assert(_width % 4 == 0, "Width of image must be a multiple of 4");
        _data = cast(ubyte[]) new ubyte16[_width * _height * _pixelSize / 16];
    }
}

class ImageFitness(Rasterizer)
{
    private
    {
        ulong _shapeCount;
        SuperImage target;
        double bestFitness = double.max;
    }

    this(string path, ulong shapeCount)
    {
        import dlib.image : convert;

        target = loadImage(path).convert!AlignedImage;
        _shapeCount = shapeCount;
    }

    size_t genomeSize()
    {
        return _shapeCount * Rasterizer.shapeBits;
    }

    double opCall(ref BitArray genome)
    {
        import core.simd : ubyte16;
        import simdutil : unpacked;

        auto source = new AlignedImage(target.width, target.height);
        auto pixels = cast(ubyte16[]) source.data;
        foreach (ref pixelPack; pixels)
        {
            pixelPack = [0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255];
        }

        size_t numberOfShapesInPopulation = genome.length / Rasterizer.shapeBits;
        foreach (index; 0 .. numberOfShapesInPopulation)
        {
            Rasterizer.rasterizeShape(pixels, target.width, target.height, genome, index * Rasterizer.shapeBits);
        }

        auto fitness = meanSquaredError(source.data, target.data);
        if (fitness < bestFitness)
        {
            source.saveImage("last.png");
            bestFitness = fitness;
        }

        return fitness;
    }
}

void draw(in Options options)
{
    import rasterizer : RectangleRasterizer;
    auto fitness = new ImageFitness!RectangleRasterizer(options.input, options.shapeCount);
    geneticAlgorithm!(fitness)(
            fitness.genomeSize,
            0.0,
            50,
            options.mutation,
            options.countEpoch,
            options.forever);
}

void main(string[] argv)
{
    auto data = getOptions(argv);
    draw(data);
}
