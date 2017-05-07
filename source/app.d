import std.stdio;
import genetic;
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

int main(string[] argv)
{
    return 0;
}
