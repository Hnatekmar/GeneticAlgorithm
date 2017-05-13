module individual;

import std.bitmanip;
import std.random;


class Individual(alias fitnessFn)
{
    private
    {
    		BitArray representation;
    }

    this(size_t size)
    {
    	foreach(i; 0..size)
    	{
    		representation ~= uniform(0, 2) == 1;
    	}
    }

    Individual mutate(float mutationRate)
    {
    	Individual!fitnessFn newIndividual = new Individual!fitnessFn(1);
    	newIndividual.representation = representation.dup();
   		foreach(i; 0..representation.length)
   		{
    		if(mutationRate < uniform01())
    		{
    			newIndividual.representation[i] = uniform(0, 2) == 0;
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

