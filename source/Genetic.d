module genetic;
import individual;
import std.random;


alias Population = Individual[];

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


Individual geneticAlgorithm(size_t genomSize, double requiredFitness, size_t populationSize, FitnessFnType evaluator)
{
    import std.stdio: writeln;
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
			auto x = (cast(size_t[]) fittest.genome);
			x.writeln;
			writeln("Fitness: ", fittest.fitness);
		}
		generationNumber += 1;
	}
	return current.getFittest();
}