module individual;

import std.bitmanip;
import std.random;

alias FitnessFnType = double function(BitArray);

class Individual
{
    private
    {
    		BitArray representation;
    		FitnessFnType fitnessFn;
    }

    this(size_t size, FitnessFnType evaluator)
    {
    	foreach(i; 0..size)
    	{
    		representation ~= uniform(0, 2) == 1;
    	}
    	fitnessFn = evaluator;
    }

    this(double function(BitArray) evaluator)
    {
    	fitnessFn = evaluator;
    }

    Individual mutate(float mutationRate)
    {
    	Individual newIndividual = new Individual(fitnessFn);
    	newIndividual.representation = representation.dup();
   		foreach(i; 0..representation.length)
   		{
    		if(mutationRate < uniform01())
    		{
    			newIndividual.representation[i] = uniform(0, 2) == 1;
    		}
    	}
    	return newIndividual;
    }

    Individual crossover(Individual individual)
    {
    	Individual newIndividual = new Individual(fitnessFn);
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

