SELECT *
FROM [portfolio project].[dbo].[covid_deaths]
WHERE continent is not null
ORDER BY 3,4


--SELECT *
--FROM dbo.covid_vaccinations$
--ORDER BY 3,4


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM[portfolio project].[dbo].[covid_deaths]
ORDER BY 1,2

-- looking at the total cases vs total deaths
-- getting the percentage by dividing total deaths by total cases then multiplying by 100

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM dbo.covid_deaths
WHERE location like '%states%'
ORDER BY 1,2


-- the total cases vs the population by dividing the total cases by population multiplying by 100 to check the death percentage to show us what percentage of the population contracted covid

SELECT location, date, total_cases, population, (total_cases/population)*100 AS death_percentagebycases
FROM dbo.covid_deaths
WHERE location like '%canada%'
ORDER BY 1,2

-- looking at the countries with the highest infection rate using population

SELECT location,population, MAX(total_cases) AS highestinfectioncount, MAX (total_cases/population)*100 AS PercentByPopInfected
FROM dbo.covid_deaths
GROUP BY population,location
ORDER BY PercentByPopInfected desc


--lets show the countries with the highest death count using population
-- im goin to need to cast the total_deaths as an integer to get a better reading

SELECT location,MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM dbo.covid_deaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount desc

--lets look at the continent with the highest death count


SELECT continent,MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM [portfolio project].[dbo].[covid_deaths]
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

--lets look at the worldwide numbers 
--using aggregate functions

--looking at the total cases per day, new deaths per day and death percentage per day

SELECT date, SUM(total_cases) AS TotalCases, SUM(cast (new_deaths AS int))AS NewDeaths, SUM (CAST(new_deaths AS int))/SUM (new_cases)*100 AS DeathPercentage
FROM dbo.covid_deaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


-- join the two tables together
--on location and date

SELECT *
FROM dbo.covid_deaths dea
join dbo.covid_vaccinations$ vac
	ON dea.location=vac.location 
	AND dea.date=vac.date


-- looking at total pouplation vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM dbo.covid_deaths dea
join dbo.covid_vaccinations$ vac
	ON dea.location=vac.location 
	AND dea.date=vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- continue analyzing data using partition by

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as rollingpplvaccinated
FROM dbo.covid_deaths dea
join dbo.covid_vaccinations$ vac
	ON dea.location=vac.location 
	AND dea.date=vac.date
ORDER BY 2,3

--USE CTE

with PopvsVac (continent, locatio, date, population,new_vaccinations, rollingpplvaccinated )
as 
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as rollingpplvaccinated
FROM dbo.covid_deaths dea
join dbo.covid_vaccinations$ vac
	ON dea.location=vac.location 
	AND dea.date=vac.date
)

SELECT * ,(rollingpplvaccinated/ population)*100
FROM PopvsVac


-- temp table
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpplvaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as rollingpplvaccinated
FROM dbo.covid_deaths dea
join dbo.covid_vaccinations$ vac
	ON dea.location=vac.location 
	AND dea.date=vac.date
	WHERE dea.continent is not null
--ORDER BY 2,3

SELECT * ,(rollingpplvaccinated/ population)*100
FROM #PercentPopulationVaccinated


--creating A view to store data to analyze

CREATE VIEW Popvsvac as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM[portfolio project].[dbo].[covid_deaths] dea
join dbo.covid_vaccinations$ vac
	ON dea.location=vac.location 
	AND dea.date=vac.date
WHERE dea.continent is not null
