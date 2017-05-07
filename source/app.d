import genetic;
import std.stdio;
import std.getopt;
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

void getoptions(string[] args)
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
    "input|i","Input file with data.", &data);

  if (helpInformation.helpWanted)
  {
    defaultGetoptPrinter("Generic algorithm for coloring pictures with geometric objects.\n",
      helpInformation.options);
  }
}

int main(string[] argv)
{
	if (argv.length > 1)
	{
		getoptions(argv);
	}
	return 0;
}
