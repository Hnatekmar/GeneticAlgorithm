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

    Individual crossover(Individual individual)
    {
        size_t gate = individual.representation.length / 2;
        bool[] bitArr;
        foreach(i; 0 .. representation.length)
        {
            bitArr ~= i <= gate ? representation[i] : individual.representation[i];
        }
        assert(bitArr.length == representation.length());
        Individual!fitnessFn newIndividual = new Individual!fitnessFn(BitArray(bitArr), false);
        return newIndividual;
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

