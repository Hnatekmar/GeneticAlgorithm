import std.getopt;
import std.variant;
import std.file;


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
in
{
    assert(args.length < 5, "Opps too many argmunt inputed");
}
body
{
		
    string input;
    ulong countEpoch;
    float mutationNumber;
    float probability = 1.0;
    auto helpInformation = getopt(
        args,
        "epoch|e","Counting epoch, number(int).", &countEpoch,
        "mutation|m","Mutation, how large mutation should be(int).", &mutationNumber,
        "probability|p","Number(float) representing probability.", &probability,
        "input|i","Input file with data.", &input
    );

		if((getcwd() ~ "/" ~ input).exists == false)
		{
			throw new NoInputParams("Inputed image file " ~ input ~ " not found");
		}

		auto data = Options(input, mutationNumber, countEpoch, probability);

    if (helpInformation.helpWanted)
    {
    defaultGetoptPrinter(
            "Generic algorithm for coloring pictures with geometric objects.\n",
            helpInformation.options
        );
    }
	return data;
}
