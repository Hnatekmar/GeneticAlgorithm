import opt;
import genetic;
import std.stdio;
import string_gen;
import std.bitmanip;
import dsfml.graphics;

void draw()
{
	auto window = new RenderWindow(VideoMode(800,600),"Genetický algoritmus");
	auto circle = new CircleShape(100);
	circle.fillColor = Color.Green;
	while (window.isOpen())
	{
		Event event;
		while(window.pollEvent(event))
		{
			if(event.type == event.EventType.Closed)
			{
				window.close();
			}
		}
		window.clear();
		window.draw(circle);
		window.display();
	}
}

void main(string[] argv)
{
	if (argv.length > 1)
	{
		getoptions(argv);
	}
	double fitness(BitArray ar){
		string test;
		const string word = "hellow";
		auto split_arr = ar.splitBitArray(5);
		foreach (sa; split_arr)
		{
			auto c = (cast(char []) cast(void []) sa)[0];
			test ~= 'A' + c;
		}
		import std.algorithm.comparison;
		auto fit = levenshteinDistanceAndPath(word,test);
		//test.writeln;
		return fit[0];
	}
	auto neco = geneticAlgorithm!fitness(25,0.0,10);
	neco.genome.printRepresentation.writeln;
}
