SELECT *
FROM Portfolioproject.dbo.coviddeaths
where continent is not null
order by 3,4

SELECT 
    location, 
    date, 
    total_cases, 
    new_cases, 
    total_deaths, 
    population
FROM 
    Portfolioproject.dbo.coviddeaths
where continent is not null
ORDER BY 
    location, 
    date;

	--looking at total cases vs total deaths
	--shows likelihood of dying if you contract covid in your country
SELECT 
    location, 
    date,
    total_cases, 
    total_deaths,
    CASE 
        WHEN total_cases IS NULL OR total_cases = 0 THEN 0
        ELSE CAST(total_deaths AS FLOAT) / total_cases*100
    END AS death_percentage
FROM 
    Portfolioproject.dbo.coviddeaths
where location like '%nigeria%'
    and continent is not null
ORDER BY 
    location, 
    date

--looking at total cases vs population
--shows what percentage of population got covid

SELECT 
    location, 
    date,
    total_cases, 
    population,
    CASE 
        WHEN TRY_CAST(population AS FLOAT) = 0 OR TRY_CAST(population AS FLOAT) IS NULL THEN 0
        ELSE (TRY_CAST(total_cases AS FLOAT) / TRY_CAST(population AS FLOAT)) * 100
    END AS infectedpopulation_percentage
FROM 
    Portfolioproject.dbo.coviddeaths
--WHERE location LIKE '%nigeria%' and continent is not null
ORDER BY 
    location, 
    TRY_CONVERT(DATE, date, 101);  -- Convert date to proper date format for sorting



--looking at country with highest infection rate compared to population

WITH MaxCases AS (
    SELECT 
        location, 
        CAST(Population AS FLOAT) AS Population,  -- Explicitly cast Population to FLOAT
        MAX(CAST(total_cases AS FLOAT)) AS Highestinfectioncount
    FROM 
        Portfolioproject.dbo.coviddeaths
    GROUP BY 
        location, 
        CAST(Population AS FLOAT)  -- Group by explicitly cast Population
)
SELECT 
    location, 
    Population,
    Highestinfectioncount,
    CASE 
        WHEN Population = 0 THEN 0
        ELSE (Highestinfectioncount / Population) * 100
    END AS infectedpopulation_percentage
FROM 
    MaxCases
ORDER BY 
    infectedpopulation_percentage DESC;


--LET'S BREAK THINGS DOWN BY CONTINENT

SELECT
    continent, 
    MAX(cast(total_deaths as int)) AS totaldeathcount
FROM
     Portfolioproject.dbo.coviddeaths
where continent is not null
GROUP BY continent
ORDER BY 
    totaldeathcount DESC;


--showing continents with the highest death count per population

--LET'S BREAK THINGS DOWN BY CONTINENT

SELECT
    continent, 
    MAX(cast(total_deaths as int)) AS totaldeathcount
FROM
     Portfolioproject.dbo.coviddeaths
where continent is not null
GROUP BY continent
ORDER BY 
    totaldeathcount DESC;




--Global Numbers

SELECT
    SUM(CAST(total_cases AS FLOAT)) AS total_cases, 
    SUM(CAST(total_deaths AS FLOAT)) AS total_deaths,
    CASE 
        WHEN SUM(CAST(total_cases AS FLOAT)) IS NULL OR SUM(CAST(total_cases AS FLOAT)) = 0 THEN 0
        ELSE (CAST(SUM(CAST(total_deaths AS FLOAT)) AS FLOAT) / SUM(CAST(total_cases AS FLOAT))) * 100
    END AS death_percentage
FROM 
    Portfolioproject.dbo.coviddeaths
WHERE 
    continent IS NOT NULL;



--looking at total population vs vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (partition by dea.location  ORDER BY dea.location, TRY_CONVERT(DATE, dea.date, 101))as running_total_vaccinations
--, (running_total_vaccinations/population)*100
FROM portfolioproject.dbo.coviddeaths as dea
join portfolioproject.dbo.covidvaccination as vac
    on dea.location = vac.location
	and dea.date = vac.date 
where dea.continent is not null
order by
	location,
    TRY_CONVERT(DATE, dea.date, 101); 



--USE CTE
with popvsvav (continent, location, date, population, new_vaccinations, running_total_vaccinations)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (partition by dea.location  ORDER BY dea.location, TRY_CONVERT(DATE, dea.date, 101))as running_total_vaccinations
--, (running_total_vaccinations/population)*100
FROM portfolioproject.dbo.coviddeaths as dea
join portfolioproject.dbo.covidvaccination as vac
    on dea.location = vac.location
	and dea.date = vac.date 
where dea.continent is not null
)
select *,  (CAST(running_total_vaccinations AS FLOAT) / CAST(population AS FLOAT)) * 100 AS vaccination_percentage
from popvsvav
order by
	location,
    TRY_CONVERT(DATE, date, 101); 


--TEMP TABLE


-- Drop the temporary table if it exists
IF OBJECT_ID('tempdb..#percentpopulationvaccinated') IS NOT NULL
    DROP TABLE #percentpopulationvaccinated;

-- Create temporary table
CREATE TABLE #percentpopulationvaccinated (
    continent NVARCHAR(225),
    location NVARCHAR(225),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    running_total_vaccinations NUMERIC
);

-- Insert data into temporary table
INSERT INTO #percentpopulationvaccinated
SELECT 
    dea.continent, 
    dea.location, 
    TRY_CONVERT(DATE, dea.date, 101) AS date, 
    TRY_CAST(dea.population AS NUMERIC) AS population, 
    TRY_CAST(vac.new_vaccinations AS NUMERIC) AS new_vaccinations,
    SUM(TRY_CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY TRY_CONVERT(DATE, dea.date, 101)) AS running_total_vaccinations
FROM 
    portfolioproject.dbo.coviddeaths AS dea
JOIN 
    portfolioproject.dbo.covidvaccination AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date 
WHERE 
    dea.continent IS NOT NULL
ORDER BY 
    dea.location,
    TRY_CONVERT(DATE, dea.date, 101);

-- Select from temporary table
SELECT 
    *,  
    (CAST(running_total_vaccinations AS FLOAT) / CAST(population AS FLOAT)) * 100 AS vaccination_percentage
FROM 
    #percentpopulationvaccinated;

-- Drop the temporary table (optional, if you no longer need it)
-- DROP TABLE #percentpopulationvaccinated;


--creating view to store data for later visualizations

CREATE VIEW populationpercent as
SELECT 
    dea.continent, 
    dea.location, 
    TRY_CONVERT(DATE, dea.date, 101) AS date, 
    TRY_CAST(dea.population AS NUMERIC) AS population, 
    TRY_CAST(vac.new_vaccinations AS NUMERIC) AS new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY TRY_CONVERT(DATE, dea.date, 101)) AS running_total_vaccinations
FROM 
    portfolioproject.dbo.coviddeaths AS dea
JOIN 
    portfolioproject.dbo.covidvaccination AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date 
WHERE 
    dea.continent IS NOT NULL
--ORDER BY 2,3

select *
from populationpercent
