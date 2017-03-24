import std.stdio;
import std.bitmanip;
import std.random;

alias FitnessFnType = double function(BitArray);
alias Population = Individual[];

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
}

Individual getFittest(Population population)
{
	import std.algorithm.searching : minElement;
	return population.minElement!"a.fitness";
}

Individual tournamentSelection(Population population, size_t tournamentSize)
{
	Population newPopulation;
	foreach(i; 0 .. tournamentSize)
	{
		newPopulation ~= population[uniform(0, population.length)];
	}
	return newPopulation.getFittest();
}

Population evolvePopulation(Population population)
{
		Population newPopulation;
		newPopulation ~= population.getFittest();
		foreach(i; 1..population.length)
		{
			auto a = population.tournamentSelection(population.length / 4);
			auto b = population.tournamentSelection(population.length / 4);
			newPopulation ~= a.crossover(b).mutate(0.45);
		}
		return newPopulation;
}

void printRepresentation(BitArray genom)
{
	(cast(size_t[]) genom).writeln;
}

Individual geneticAlgorithm(size_t genomSize, double requiredFitness, size_t populationSize, FitnessFnType evaluator)
{
	Population current;
	foreach(i; 0..populationSize)
	{
		current ~= new Individual(genomSize, evaluator);
	}
	size_t generationNumber = 0;
	while(current.getFittest.fitness != requiredFitness)
	{
		current = current.evolvePopulation();
		if(generationNumber % 1000 == 0)
		{
			auto fittest = current.getFittest();
			writeln("===== Generation: ", generationNumber, " =====");
			auto x = (cast(size_t[]) fittest.representation);
			x.writeln;
			writeln("Fitness: ", fittest.fitness);
		}
		generationNumber += 1;
	}
	current.getFittest.representation.printRepresentation;
	return current.getFittest();
}


double value(size_t[] arr, size_t x)
{
	double value = 0;
	foreach(i; 0..arr.length)
	{
		value += (arr[i] ^^ (arr.length - i)) * x;
	}
	return value; 
}

double fitness(BitArray array)
{
	auto generationPolygon = (cast(size_t[]) array);
	size_t[] targetPolynom = [1, 5, 6];
	double error = 0;
	size_t m = 100;
	for(size_t x = 1; x <= m; x++)
	{
		error += (generationPolygon.value(x) - targetPolynom.value(x)) ^^ 2;
	}
	return (1.0 / m) * error;
}

int main(string[] argv)
{
	geneticAlgorithm(32 * 3, 0.0, 100, &fitness); 
	getchar();
    return 0;
}
