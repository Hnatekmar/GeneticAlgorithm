import std.getopt;
import std.file;
import std.stdio;
import core.stdc.stdlib;

struct Options {

    ulong countEpoch;
    float mutation;
    string input;
    float probability;
    bool forever;
    ulong shapeCount;

    this(string inp, float mutate, ulong  count, float prob, bool forever, ulong shapeCount)
    {
        this.input = inp;
        this.mutation = mutate;
        this.countEpoch = count;
        this.probability = prob;
        this.forever = forever;
        this.shapeCount = shapeCount;
    }
}

Options getOptions(string[] args)
{
    string input;
    ulong countEpoch = 10_000;
    float mutationNumber = 0.99f;
    float probability = 0.01;
    ulong shapeCount = 50;
    bool forever = false;
    try
    {
        auto helpInformation = getopt(
                args,
                "epoch|e", "Counting epoch, number (ulong).", &countEpoch,
                "probability|p", "Number (float) representing probability.", &probability,
                "mutation|m", "Mutation, how large mutation is, value MUST be between 0.0 and 1", &mutationNumber,
                "forever|f", "Run program forever", &forever,
                "shapeCount|s", "Number of shapes used for approximation (s > 0)", &shapeCount,
                config.required,
                "input|i", "This is the image you MUST input", &input
                );

        if (!input.exists && input != "")
        {
            helpInformation.helpWanted = true;
            stderr.writeln("ERROR: File you tried to input " ~ input ~ " does not exists!");
        }

        if(!(mutationNumber >= 0.0f && mutationNumber <= 1.0f))
        {
            helpInformation.helpWanted = true;
            stderr.writeln("ERROR: Mutation value is not correct");
        }

        if (shapeCount == 0)
        {
            helpInformation.helpWanted = true;
            stderr.writeln("ERROR: number of shapes has to be at least 1");
        }

        if (helpInformation.helpWanted)
        {
            defaultGetoptPrinter(
                    "\nHELP INFO: Generic algorithm coloring pictures with geometric objects.\n",
                    helpInformation.options
                    );
        }

        if (helpInformation.helpWanted)
        {
            exit(-1);
        }
    }
    catch(GetOptException e)
    {
        stderr.writeln(e.msg);
        exit(-1);
    }
    return Options(input, mutationNumber, countEpoch, probability, forever, shapeCount);
}
