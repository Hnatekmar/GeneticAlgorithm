import std.getopt;
import std.variant;

Variant[string] getOptions(string[] args)
in
{
    assert(args.length > 1, "Inputed empty paramters");
    assert(args.length < 5, "Opps too many argmunt inputed");
}
body
{
    string input;
    int count_epoch;
    int mutation_number;
		Variant[string] data;
    float probability = 0.0;
    auto helpInformation = getopt(
        args,
        "epoch|e","Counting epoch, number(int).", &count_epoch,
        "mutation|m","Mutation, how large mutation should be(int).", &mutation_number,
        "probability|p","Number(float) representing probability.", &probability,
        "input|i","Input file with data.", &input
    );

		data["count"] = count_epoch;
		data["mutate"] = mutation_number;
		data["prob"] = probability;
		data["input"] = input;

    if (helpInformation.helpWanted)
    {
    defaultGetoptPrinter(
            "Generic algorithm for coloring pictures with geometric objects.\n",
            helpInformation.options
        );
    }
	return data;
}
