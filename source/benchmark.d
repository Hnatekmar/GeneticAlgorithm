import std.range;
import util;
import std.stdio;

void profile(alias Fn)(string name, string plotName, size_t from, size_t to, size_t step, uint numberOfTries = 500)
in
{
    assert(from < to);
}
body
{
    import std.datetime: benchmark;
    import std.algorithm: map;
    long[] time;
    auto xAxis = iota(from, to).array;
    time.reserve(to - from);
    size_t it = from;
    while(it <= to)
    {
        it += step;
        auto result = benchmark!(() => Fn(it))(numberOfTries);
        time ~= result[0].nsecs;
    }
    import ggplotd.aes : aes;
    import ggplotd.axes : xaxisLabel, yaxisLabel, xaxisOffset, yaxisOffset, xaxisRange, yaxisRange;
    import ggplotd.geom : geomLine;
    import ggplotd.ggplotd : GGPlotD, putIn, Margins, title;
    import ggplotd.stat : statFunction;

    auto gg = xAxis.zip(time)
            .map!(a => aes!("x", "y", "colour")(a[0], a[1], "a"))
            .geomLine
            .putIn(GGPlotD());
    gg.put(xaxisLabel("n"));

    gg.put(yaxisLabel("ns"));

    gg.put(title(plotName));

    gg.save(name, 800, 600);
}

void main()
{
    ushort[2000] arr;
    profile!(n => cast(void)meanSquaredError(arr[0..(n - 1)], arr[0..(n - 1)]))("mse.png", "MSE", 1, 2_000, 1);
}
