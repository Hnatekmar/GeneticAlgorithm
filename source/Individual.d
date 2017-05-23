module individual;

import std.bitmanip;
import std.random;
import std.datetime;


class Individual(alias fitnessFn)
{
	private
	{
		Mt19937 gen;
		BitArray representation;
	}

	this(size_t size)
	{
		auto ct = Clock.currTime();
		gen.seed(cast(uint)(ct.toUnixTime()));
		foreach(i; 0..size)
		{
			representation ~= uniform(0, 2, gen) == 1;
		}
	}

	Individual mutate(float mutationRate)
	{
		Individual!fitnessFn newIndividual = new Individual!fitnessFn(1);
		newIndividual.representation = representation.dup();
		foreach(i; 0..representation.length)
		{
			if(mutationRate < uniform01(gen))
			{
				newIndividual.representation[i] = uniform(0, 2, gen) == 0;
			}
		}
		return newIndividual;
	}

	Individual crossover(Individual individual)
	{
		Individual!fitnessFn newIndividual = new Individual!fitnessFn(1);
		size_t gate = uniform(1, individual.representation.length - 1);
		bool[] bitArr;
		foreach(i; 0 .. representation.length)
		{
			bitArr ~= i <= gate ? representation[i] : individual.representation[i];
		}
		newIndividual.representation = BitArray(bitArr);
		return newIndividual;
	}

	@property double fitness()
	{
		return fitnessFn(representation);
	}

	@property BitArray genome()
	{
		return this.representation;
	}
}

