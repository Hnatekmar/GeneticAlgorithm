module genetic;
import individual;
import std.random;

Individual!fitness getFittest(alias fitness)(Individual!(fitness)[] population)
{
	import std.algorithm.searching : minElement;
	return population.minElement!"a.fitness";
}

Individual!fitness tournamentSelection(alias fitness)(Individual!fitness[] population, size_t tournamentSize)
{
	Individual!fitness[] newPopulation;
	foreach(i; 0 .. tournamentSize)
	{
		newPopulation ~= population[uniform(0, population.length)];
	}
	return newPopulation.getFittest();
}

Individual!fitness[] evolvePopulation(alias fitness)(Individual!fitness[] population,float mutation)
{
	Individual!fitness[] newPopulation;
	newPopulation ~= population.getFittest!fitness();
	foreach(i; 1..population.length)
	{
		auto a = population.tournamentSelection!fitness(population.length / 2);
		auto b = population.tournamentSelection!fitness(population.length / 2);
		newPopulation ~= a.crossover(b).mutate(mutation);
	}
	return newPopulation;
}


Individual!fitness geneticAlgorithm(alias fitness, alias print)(size_t genomSize, double requiredFitness, size_t populationSize,float mutationRate)
{
	import std.stdio: writeln;
	Individual!fitness[] current;
	foreach(i; 0..populationSize)
	{
		current ~= new Individual!fitness(genomSize);
	}
	size_t generationNumber = 0;
	while(current.getFittest.fitness > requiredFitness)
	{
		current = current.evolvePopulation!fitness(mutationRate);
		if(generationNumber % 100 == 0)
		{
            auto fittest = current.getFittest!fitness();
            writeln("===== Generation: ", generationNumber, " =====");
            writeln("Fitness: ", fittest.fitness);
        }
		generationNumber += 1;
	}
	writeln("==== Best genom =====");
	print(current.getFittest().genome());
	return current.getFittest();
}
