import opt;
import genetic;
import std.stdio;
import string_gen;
import std.bitmanip;
import dsfml.window;
import dsfml.graphics;
import std.random;

void draw()
{
	ContextSettings settings;
	settings.antialiasingLevel = 8;
	auto style = Window.Style.DefaultStyle;
	short vectorX = 800;
	short vectorY = 600;
	auto window = new RenderWindow(VideoMode(vectorX,vectorY),"Genetický algoritmus");
	//auto window = new RenderWindow(VideoMode(800,600),"Genetický algoritmus",style,settings);//too hot cpu
	CircleShape[] field;
	foreach (_;0..100)
	{
		auto circle = new CircleShape(uniform(10,100));
		circle.position = Vector2f(uniform(0,vectorX),uniform(0,vectorY));
		circle.fillColor = Color(cast(ubyte) uniform(10,100),cast(ubyte) uniform(10,100),cast(ubyte) uniform(10,100));//random color
		field ~= circle;
	}
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
		window.clear(Color.White);
		foreach (circle;field)
		{
			window.draw(circle);
		}
		window.display();
	}
}

double fitness(string word, BitArray ar){
	string test;
	auto split_arr = ar.splitBitArray(5);
	foreach (sa; split_arr)
	{
		auto c = (cast(char []) cast(void []) sa)[0];
		test ~= 'A' + c;
	}
	import std.algorithm.comparison;
	auto fit = levenshteinDistanceAndPath(word,test);
	return fit[0];
}

void callWithString(string what)()
{
	geneticAlgorithm!(fitness!what, printRepresentation)(what.length * 5, 0.0, 20,0.95);
}

void main(string[] argv)
{
	if (argv.length > 1)
	{
		getoptions(argv);
	}
	auto word = "HELLO";
	draw();
	//geneticAlgorithm!((ar => fitness(word, ar)), printRepresentation)(word.length * 5, 0.0, 20, 0.95);
}
