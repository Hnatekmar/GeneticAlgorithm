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
		double calculatedFitness;
	}

    this(BitArray array, bool recalculateFitness = true)
    {
        representation = array;
        if(recalculateFitness)
            calculatedFitness = fitnessFn(array);
		auto ct = Clock.currTime();
		gen.seed(cast(uint)(ct.toUnixTime()));
    }

	this(size_t size)
	{
		foreach(i; 0..size)
		{
			representation ~= uniform(0, 2) == 0;
		}
		calculatedFitness = fitnessFn(representation);
	}

	Individual mutate(float mutationRate)
	{
		auto newRepresentation = representation.dup();
		foreach(i; 0..representation.length)
		{
			if(mutationRate < uniform01(gen))
			{
				newRepresentation[i] = uniform(0, 2, gen) == 0;
			}
		}
		assert(newRepresentation.length() == representation.length());
		Individual!fitnessFn newIndividual = new Individual!fitnessFn(newRepresentation);
		return newIndividual;
	}

    Individual crossover(Individual that)
    in {
        assert(this.representation.length == that.representation.length, "Individuals to crossover must have a representation of the same length");
    }
    out (result) {
        assert(result.representation.length == this.representation.length, "The result of a crossover must have a representation of the same length as its parents");
    }
    body {
        import util : mergeBitArray;

        const gate = this.representation.length / 2;
        auto newRep = mergeBitArray(gate, this.representation, that.representation);
        return new Individual(newRep, false);
    }

	@property double fitness()
	{
	    return calculatedFitness;
	}

	@property ref BitArray genome()
	{
		return representation;
	}
}

