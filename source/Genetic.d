module genetic;
import individual;
import std.random;

Individual!fitnes getFittest(alias fitness)(Individual!fitness[] population)
{
	import std.algorithm.searching : minElement;
	return population.minElement!"a.fitness";
}

Individual!fitness tournamentSelection(alias fitness)(Population population, size_t tournamentSize)
{
	Individual!fitness[] newPopulation;
	foreach(i; 0 .. tournamentSize)
	{
		newPopulation ~= population[uniform(0, population.length)];
	}
	return newPopulation.getFittest();
}

Individual!fitness[] evolvePopulation(alias fitness)(Population population)
{
		Individual!fitness[] newPopulation;
		newPopulation ~= population.getFittest();
		foreach(i; 1..population.length)
		{
			auto a = population.tournamentSelection(population.length / 4);
			auto b = population.tournamentSelection(population.length / 4);
			newPopulation ~= a.crossover(b).mutate(0.45);
		}
		return newPopulation;
}


Individual!fitness geneticAlgorithm(alias fitness)(size_t genomSize, double requiredFitness, size_t populationSize)
{
    import std.stdio: writeln;
	Population current;
	foreach(i; 0..populationSize)
	{
		current ~= new Individual!fitness(genomSize, evaluator);
	}
	size_t generationNumber = 0;
	while(current.getFittest.fitness > requiredFitness)
	{
		current = current.evolvePopulation();
		if(generationNumber % 1000 == 0)
		{
			auto fittest = current.getFittest();
			writeln("===== Generation: ", generationNumber, " =====");
			auto x = (cast(size_t[]) fittest.genome);
			x.writeln;
			writeln("Fitness: ", fittest.fitness);
		}
		generationNumber += 1;
	}
	return current.getFittest();
}