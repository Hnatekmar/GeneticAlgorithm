import std.getopt;
import std.file;
import std.stdio;
import core.stdc.stdlib;

struct Options
{
    ulong maxEpoch = 10_000;
    ulong shapeCount = 100;
    float mutation = 0.001;
    string input;
    bool forever;
}

Options getOptions(string[] args)
{
    Options options;
    try
    {
        auto helpInformation = getopt(
                args,
                "epoch|e", "Counting epoch, number (ulong).", &options.maxEpoch,
                "mutation|m", "Mutation, how large mutation is, value MUST be between 0.0 and 1",
                &options.mutation,
                "forever|f", "Run program forever", &options.forever,
                "shapeCount|s", "Number of shapes used for approximation (s > 0)", &options.shapeCount,
                config.required,
                "input|i", "This is the image you MUST input", &options.input
                );

        if (!options.input.exists && options.input != "")
        {
            helpInformation.helpWanted = true;
            stderr.writeln("ERROR: File you tried to input " ~ options.input ~ " does not exists!");
        }

        if(!(options.mutation >= 0.0f && options.mutation <= 1.0f))
        {
            helpInformation.helpWanted = true;
            stderr.writeln("ERROR: Mutation value is not correct");
        }

        if (options.shapeCount == 0)
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
    return options;
}
