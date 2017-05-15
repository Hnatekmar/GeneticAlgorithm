import std.getopt;

void getoptions(string[] args)
in
{
	assert(args.length > 1, "Inputed empty paramters");
	assert(args.length < 5, "Opps too many argmunt inputed");
}
body
{
	string data = "";
	int count_epoch = 0;
	int mutation_number = 0;
	float probability = 0.0;
  auto helpInformation = getopt(
    args,
    "epoch|e","Counting epoch, number(int).", &count_epoch,
    "mutation|m","Mutation, how large mutation should be(int).", &mutation_number,
    "probability|p","Number(float) representing probability.", &probability,
    "input|i","Input file with data.", &data
	);
	import std.stdio;
	data.writeln;
  if (helpInformation.helpWanted)
  {
    defaultGetoptPrinter(
			"Generic algorithm for coloring pictures with geometric objects.\n",
			helpInformation.options
		);
  }
}
