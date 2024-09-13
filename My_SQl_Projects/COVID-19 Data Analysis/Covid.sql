-- **Questions Addressed:**
-- 1. Basic COVID-19 Statistics: Query to retrieve location, date, total cases, new cases, total deaths, and population.
-- 2. Total Cases vs Total Deaths in India and Pakistan: Calculate death percentage from total cases for India and Pakistan.
-- 3. Total Cases vs Population in India and Pakistan (Date >= 2021): Calculate percentage of the population infected in India and Pakistan from 2021 onwards.
-- 4. Countries with Highest Total Cases: Find countries with the highest number of total cases.
-- 5. Countries with Highest Infection Rate Compared to Population: Identify countries with the highest infection rate relative to their population.
-- 6. Countries with Highest Total Deaths: Determine countries with the highest total number of deaths.
-- 7. Countries with Highest Death Rate Compared to Population: Identify countries with the highest death rate relative to their population.
-- 8. Global Statistics: Summarize global total cases, total deaths, and death percentage over time.
-- 9. New Vaccinations per Population in India: Analyze new vaccinations per population and cumulative vaccinations for India.
-- 10. Create View for New Vaccinations per Population in India: Create a view to analyze new vaccinations per population in India.

-- Enable local file import
SET GLOBAL local_infile = 1;

-- Import data into covid_deaths
LOAD DATA LOCAL INFILE '/Users/darshanpatel/Desktop/covid project/covid_deaths.csv'
INTO TABLE covid_deaths
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Import data into covid_vaccination
LOAD DATA LOCAL INFILE '/Users/darshanpatel/Desktop/covid project/covid_vaccination.csv'
INTO TABLE covid_vaccination
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Basic COVID-19 Statistics
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths;

-- Total Cases vs Total Deaths in India and Pakistan
SELECT location, date, total_cases, total_deaths, 
       (total_deaths / total_cases) * 100 AS Deathpercentage
FROM covid_deaths
WHERE location LIKE '%india%' OR location LIKE '%pakistan%'
ORDER BY location, date;

-- Total Cases vs Population in India and Pakistan (Date >= 2021)
SELECT location, date, total_cases, population,
       (total_cases / population) * 100 AS percentage_of_population
FROM covid_deaths
WHERE (location LIKE '%india%' OR location LIKE '%pakistan%')
  AND date >= '2021-01-08'
ORDER BY location, date;

-- Countries with Highest Total Cases
SELECT location, MAX(total_cases) AS Highest_infection_count
FROM covid_deaths
GROUP BY location, population
ORDER BY Highest_infection_count DESC;

-- Countries with Highest Infection Rate Compared to Population
SELECT location, population,
       MAX(total_cases) AS Highest_infection_count,
       (MAX(total_cases) / population) * 100 AS percentage_population_infected
FROM covid_deaths
GROUP BY location, population
ORDER BY percentage_population_infected DESC;

-- Countries with Highest Total Deaths
SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_deaths
GROUP BY location
ORDER BY total_death_count DESC;

-- Countries with Highest Death Rate Compared to Population
SELECT location, population,
       MAX(total_deaths) AS total_death_count,
       (MAX(total_deaths) / population) * 100 AS percentage_population_died
FROM covid_deaths
GROUP BY location, population
ORDER BY percentage_population_died DESC;

-- Global Statistics
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths,
       (SUM(new_deaths) / SUM(new_cases)) * 100 AS Death_percentage
FROM covid_deaths
GROUP BY date
ORDER BY date;

-- New Vaccinations per Population in India
WITH vaccination AS (
    SELECT dea.continent, dea.location, dea.date, dea.population,
           vac.new_vaccinations,
           (vac.new_vaccinations / dea.population) * 100 AS new_vac_per_pop,
           SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS total_vaccination
    FROM covid_deaths dea
    JOIN covid_vaccination vac ON dea.location = vac.location AND dea.date = vac.date
)
SELECT *, (total_vaccination / population) * 100 AS total_vac_per_pop
FROM vaccination
WHERE location LIKE '%india%'
ORDER BY date DESC
LIMIT 5;

-- Create View for New Vaccinations per Population in India
CREATE VIEW new_vaccination_per_population_india AS
SELECT dea.continent, dea.location, dea.date, dea.population,
       vac.new_vaccinations,
       (vac.new_vaccinations / dea.population) * 100 AS new_vac_per_pop,
       SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS total_vaccination
FROM covid_deaths dea
JOIN covid_vaccination vac ON dea.location = vac.location AND dea.date = vac.date;
