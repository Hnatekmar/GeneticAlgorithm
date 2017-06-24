module draw;

import dlib.image;
import std.algorithm.comparison;

struct Rect
{
    Color4f color;
    ubyte x, y;
    ushort width, height;
}

struct Circle
{
    Color4f color;
    ubyte x, y;
    ushort radius;
}

void rasterizeRectangles(ref SuperImage image, in Rect[] rects)
{
    import std.range: iota;
    import std.parallelism: parallel;
    foreach(ref rect; rects)
    {
        auto fromX = max(rect.x, 0);
        auto toX = min(rect.x + rect.width, image.width());
        auto fromY = max(rect.y, 0);
        auto toY = min(rect.y + rect.height, image.height());
        foreach(x; parallel(iota(fromX, toX)))
        {
            foreach(y; fromY .. toY)
            {
                image[x, y] = alphaOver(image[x, y], rect.color);
            }
        }
    }
}

void rasterizeCircles(ref SuperImage image, in Circle[] circles)
{
    foreach(circle; circles)
    {
        auto fromX = max(circle.x - circle.radius, 0);
        auto toX = min(circle.x + circle.radius, image.width());
        auto fromY = max(circle.y - circle.radius, 0);
        auto toY = min(circle.y + circle.radius, image.height());

        foreach(x; fromX .. toX)
        {
            foreach(y; fromY .. toY)
            {
                if((x - circle.x) ^^ 2 + (y - circle.y) ^^ 2 <= circle.radius ^^ 2)
                {
                    image[x, y] = alphaOver(image[x, y], circle.color);
                }
            }
        }
    }
}
