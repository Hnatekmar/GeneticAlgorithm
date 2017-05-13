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

Individual!fitness[] evolvePopulation(alias fitness)(Individual!fitness[] population)
{
		Individual!fitness[] newPopulation;
		newPopulation ~= population.getFittest!fitness();
		foreach(i; 1..population.length)
		{
			auto a = population.tournamentSelection!fitness(population.length / 4);
			auto b = population.tournamentSelection!fitness(population.length / 4);
			newPopulation ~= a.crossover(b).mutate(0.95);
		}
		return newPopulation;
}


Individual!fitness geneticAlgorithm(alias fitness, alias print)(size_t genomSize, double requiredFitness, size_t populationSize)
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
		current = current.evolvePopulation!fitness();
		if(generationNumber % 1000 == 0)
		{
			auto fittest = current.getFittest!fitness();
			writeln("===== Generation: ", generationNumber, " =====");
			print(fittest.genome());
			writeln("Fitness: ", fittest.fitness);
		}
		generationNumber += 1;
	}
	writeln("==== Best genom =====");
	print(current.getFittest().genome());
	return current.getFittest();
}