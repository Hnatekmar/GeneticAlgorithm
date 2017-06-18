import std.getopt;
import std.variant;
import std.file;
import std.stdio;


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
    float mutationNumber = 0.99;
    float probability = 1.0;
    auto helpInformation = getopt(
            args,
            "epoch|e","Counting epoch, number (ulong).", &countEpoch,
            "mutation|m","Mutation, how large mutation should be(int).", &mutationNumber,
            "probability|p","Number (float) representing probability.", &probability,
            "input|i","Input file with data.", &input
            );

    if(input.exists == false && input != "")
    {
        //throw new NoInputParams("Inputed image file " ~ input ~ " not found");
        writeln("File you tried to input " ~ input ~ " does not exists!");
    }

    auto opt = Options(input, mutationNumber, countEpoch, probability);

    if (helpInformation.helpWanted)
    {
    defaultGetoptPrinter(
            "Generic algorithm for coloring pictures with geometric objects.\n",
            helpInformation.options
        );
    }
	return opt;
}
