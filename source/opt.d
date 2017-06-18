import std.getopt;
import std.file;
import std.stdio;
import core.stdc.stdlib;

struct Options {

    ulong countEpoch;
    float mutation;
    string input;
    float probability;

    this(string inp, float mutate, ulong  count, float prob)
    {
        this.input = inp;
        this.mutation = mutate;
        this.countEpoch = count;
        this.probability = prob;
    }
}

class NoInputParams : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

Options getOptions(string[] args)
{
    string input;
    ulong countEpoch;
    float mutationNumber = 0.99f;
    float probability;
    bool forever = false;
    auto helpInformation = getopt(
            args,
            "epoch|e","Counting epoch, number (ulong).", &countEpoch,
            "probability|p","Number (float) representing probability.", &probability,
            "mutation|m","Mutation, how large mutation is, value MUST be between 0.0 and 1", &mutationNumber,
            "forever|f", "Run program forever", &forever,
            std.getopt.config.required,
            "input|i","This is the image you MUST input", &input,
            );

    if((!input.exists && input != "") || !(mutationNumber >= 0.0f && mutationNumber <= 1.0f))
    {
        helpInformation.helpWanted = true;
        if (!input.exists)
        {
            stderr.writeln("ERROR: File you tried to input " ~ input ~ " does not exists!");
        }
        if (!(mutationNumber >= 0.0f && mutationNumber <= 1.0f))
        {
            stderr.writeln("ERROR: Mutation value is not correct");
        }
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

    return Options(input, mutationNumber, countEpoch, probability);
}
