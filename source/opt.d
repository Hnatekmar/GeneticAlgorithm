import std.getopt;
import std.variant;


struct Options {

		int countEpoch;
		float mutation;
		string input;
		float probability;

		this(string inp, float mutate, int count, float prob)
		{
			this.input = inp;
			this.mutation = mutate;
			this.countEpoch = count;
			this.probability = prob;
		}
}

Options getOptions(string[] args)
in
{
    assert(args.length > 1, "Inputed empty paramters");
    assert(args.length < 5, "Opps too many argmunt inputed");
}
body
{
    string input;
    int countEpoch;
    int mutationNumber;
    float probability = 0.0;
    auto helpInformation = getopt(
        args,
        "epoch|e","Counting epoch, number(int).", &countEpoch,
        "mutation|m","Mutation, how large mutation should be(int).", &mutationNumber,
        "probability|p","Number(float) representing probability.", &probability,
        "input|i","Input file with data.", &input
    );

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
