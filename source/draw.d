module draw;

import dlib.image;

struct Rect
{
    Color4f color;
    ubyte x, y;
    ushort width, height;
}

void rasterizeRectangles(ref SuperImage image, in Rect[] rects)
{
    foreach(ref rect; rects)
    {
        foreach(x; rect.x .. (rect.x + rect.width))
        {
            foreach(y; rect.y .. (rect.y + rect.height))
            {
                if( x >= 0 &&
                    x < image.width &&
                    y >= 0 &&
                    y < image.height)
                {
                    image[x, y] = alphaOver(image[x, y], rect.color);
                }
            }
        }
    }
}
