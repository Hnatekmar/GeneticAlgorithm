module string_gen;

import std.stdio;
import std.random;
import std.bitmanip;

BitArray generateRandomString(size_t len,size_t gen_size)
{
	BitArray result;
	foreach (_;0..len)
	{
		result ~= BitArray([cast(char) uniform(32, 127)], 7);
		//writeln((cast(char[]) cast(void []) a)[0]);
	}
	return result;
}

string generateString(size_t count){
	string newone = "";
	string alpha = "abcdefghijklmnopqrstuvwxyz0123456789";
	auto a = uniform(0,15);

	for (size_t i = 0; i <= count; i++){
		newone ~= alpha[uniform(0,alpha.length)];
	}
	return newone;
}

BitArray[] splitBitArray(BitArray arr, size_t chunkSize)
in // Před spuštěním funkce
{
	assert(arr.length >= chunkSize, "Velikost bitArray musí být >= jak velikost chunku!");
	assert(chunkSize != 0, "Velikost chunku nesmí být 0.");
	assert(arr.length % chunkSize == 0, "Velikost bitArray musí být dělitelná velikostí chunku!");
}
out(result)
{
	assert(result.length == arr.length / chunkSize, "Velikost musí být stejná");
}
body // Tělo funkce
{
	BitArray[] chunks;
	for(size_t chunk_start = 0; chunk_start < arr.length; chunk_start += chunkSize)
	{
		BitArray chunk;
		for(size_t i = 0; i < chunkSize; i++)
		{
			chunk ~= arr[chunk_start + i];
		}
		chunks ~= chunk;
	}
	return chunks;
}

string bitToString(BitArray arr)
{
	auto answer = "";
	auto chunks = splitBitArray(arr, 5);
	foreach(chunk; chunks)
	{
		auto chunkValues = cast(void[]) chunk;
		char[] chars = cast(char[]) chunkValues;
        answer ~= 'A' + chars[0];
	}
	return answer;
}

void printRepresentation(BitArray arr)
{
    bitToString(arr).writeln;
}
