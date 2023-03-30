--				=================================================================================
--				Name:		HUMPHREY MAIRURA
--				Project:	SQL - DATA EXPLORATION PROJECT IN SQL SERVER 
--				Dataset:	The World COVID-19 DATA --(https://ourworldindata.org/covid-deaths)
--				Date:		03/30/2023
--				
---				=================================================================================

--						 PART 1. Selecting the Data I will be using
--=================================================================================================
USE [PortfolioProject]
GO
--Overview of the Tables I will be Using 
SELECT	*
FROM	[dbo].[CovidDeaths]

SELECT	*
FROM	[dbo].[CovidVaccinations]

--================================================================================================
--1. Selecting the Data I will be Using
SELECT		continent,
			[location],
			[date],
			total_cases,
			new_cases,
			total_deaths,
			[population]
FROM		[dbo].[CovidDeaths]
WHERE		continent IS NOT NULL
ORDER BY	[location],
			[date]
--==============================================================================================
--2. Total Cases Vs Total Deaths Per Year/Month/Day
--This shows the likelihood of dying if you contract covid in a country
SELECT		continent,
			location,
			YEAR(date) AS Year,
			MONTH(date) AS Month,
			DAY(date) Day, 
			total_cases,
			new_cases,
			total_deaths,
			ROUND(CAST(total_deaths AS FLOAT) / NULLIF(total_cases, 0) * 100, 2) AS mortality_rate
FROM		[dbo].[CovidDeaths]
WHERE		continent IS NOT NULL
ORDER BY	location, 
			YEAR(date),
			MONTH(date),
			DAY(date)

-- =================================================================================================
--3. Total Cases Per Population
SELECT		continent,
			location,
			YEAR(date) AS Year,
			MONTH(date) AS Month,
			DAY(date) Day,
			total_cases,
			population,
			total_deaths,
			ROUND(CAST(total_cases AS FLOAT) / NULLIF(population, 0) * 100, 2) AS totalCases_perc
FROM		[dbo].[CovidDeaths]
WHERE		continent IS NOT NULL
ORDER BY	location, 
			YEAR(date),
			MONTH(date),
			DAY(date)

-- ===============================================================================================
--4. Countries with highest Infection rate compared to population 
SELECT		continent,
			location,
			YEAR(date) AS Year,
			MONTH(date) AS Month,
			DAY(date) Day,
			population,
			MAX(total_cases) highest_infection_count,
			ROUND(CAST(total_cases AS FLOAT) / NULLIF(population, 0) * 100, 2) AS infection_rate
FROM		[dbo].[CovidDeaths]
--WHERE		location = 'United States'
GROUP BY	continent,
			location,
			YEAR(date),
			MONTH(date),
			DAY(date),
			population,
			total_cases
ORDER BY	infection_rate desc
-- ==============================================================================================		
-- 5. Total Deaths
--Shows countries with highest deaths 
SELECT		location,
			CAST(MAX(total_deaths) AS INT) AS TotalDeathCount
FROM		[dbo].[CovidDeaths]
WHERE		continent IS NOT NULL
GROUP BY	location
ORDER BY	TotalDeathCount DESC

---==============================================================================================
---- 6. Total Deaths
--Shows continents with highest deaths 
SELECT		continent,
			CAST(MAX(total_deaths) AS INT) AS TotalDeathCount
FROM		[dbo].[CovidDeaths]
WHERE		continent IS NOT NULL
GROUP BY	continent
ORDER BY	TotalDeathCount DESC
--======================================================================================================================================

--						PART 2: GLOBAL NUMBERS

--======================================================================================================================================
--1. Total cases vs deaths across the world
SELECT		YEAR(date) AS Year,
			MONTH(date) AS Month,
			DAY(date) AS Day,
			SUM(new_cases) AS new_cases_total,
			SUM(new_deaths) AS new_deaths_total,
			ROUND(SUM(ISNULL(CAST(new_deaths AS FLOAT), 0)) / NULLIF(SUM(ISNULL(CAST(new_cases AS FLOAT), 0)), 0) * 100, 2) AS Deathperc
FROM		[dbo].[CovidDeaths]
WHERE		continent IS NOT NULL
GROUP BY	YEAR(date) ,
			MONTH(date) ,
			DAY(date)
ORDER BY	Deathperc DESC
-- ======================================================================================================================================
-- 2. Getting the Rolling vaccinated numbers per day
-- i. Using Joins on the [dbo].[CovidDeaths] and the [dbo].[CovidVaccinations] Tables

SELECT		a.continent,
			a.location,
			YEAR(a.date) AS Year,
			MONTH(a.date) AS Month,
			DAY(a.date) AS Day,
			a.population,
			b.new_vaccinations,
			SUM(b.new_vaccinations) OVER (
			PARTITION BY a.location ORDER BY a.location,a.date
			) AS RollingPeopleVaccinated
FROM		[dbo].[CovidDeaths] a
INNER JOIN	[dbo].[CovidVaccinations] b
ON			a.location = b.location
AND			a.date = b.date
WHERE		a.continent IS NOT NULL 
ORDER BY	1,2,3

-- =======================================================================================================================================
--USING CTE
WITH VaccinatedPop AS	(
							SELECT	a.continent,
									a.location,
									YEAR(a.date) AS Year,
									MONTH(a.date) AS Month,
									DAY(a.date) AS Day,
									a.population,
									b.new_vaccinations,
									SUM(b.new_vaccinations) OVER (
										PARTITION BY a.location ORDER BY a.location, a.date
									) AS RollingPeopleVaccinated
							FROM	[dbo].[CovidDeaths] a
									INNER JOIN [dbo].[CovidVaccinations] b
										ON a.location = b.location
										AND a.date = b.date
							WHERE	a.continent IS NOT NULL 
						)

SELECT		*,
			ROUND(CAST(RollingPeopleVaccinated AS DECIMAL(18,6))/CAST(population AS DECIMAL(18,6)) * 100, 2) AS VaccinationRate
FROM		VaccinatedPop 
ORDER BY	1,2,3 DESC

-- ========================================================================================================================================
--USING TEMP TABLE
DROP TABLE IF EXISTS #VaccinatedPop
CREATE TABLE #VaccinatedPop	(	continent	VARCHAR (250),
								location	VARCHAR (250),
								date		DATETIME,
								population	NUMERIC,
								new_vaccinations NUMERIC,
								RollingPeopleVaccinated NUMERIC
							)
INSERT INTO #VaccinatedPop 
SELECT		a.continent,
			a.location,
			YEAR(a.date) AS Year,
			MONTH(a.date) AS Month,
			DAY(a.date) AS Day,
			a.population,
			b.new_vaccinations,
			SUM(b.new_vaccinations) OVER (
			PARTITION BY a.location ORDER BY a.location,a.date
			) AS RollingPeopleVaccinated
FROM		[dbo].[CovidDeaths] a
INNER JOIN	[dbo].[CovidVaccinations] b
ON			a.location = b.location
AND			a.date = b.date
WHERE		a.continent IS NOT NULL 

-- ==================================================================================================================================================================

--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS
IF OBJECT_ID('v_VaccinatedPop') IS NOT NULL
    DROP VIEW v_VaccinatedPop
GO
CREATE VIEW v_VaccinatedPop

AS 
		SELECT		YEAR(date) AS Year,
					MONTH(date) AS Month,
					DAY(date) AS Day,
					SUM(new_cases) AS new_cases_total,
					SUM(new_deaths) AS new_deaths_total,
					ROUND(SUM(ISNULL(CAST(new_deaths AS FLOAT), 0)) / NULLIF(SUM(ISNULL(CAST(new_cases AS FLOAT), 0)), 0) * 100, 2) AS Deathperc
		FROM		[dbo].[CovidDeaths]
		WHERE		continent IS NOT NULL
		GROUP BY	YEAR(date),
					MONTH(date),
					DAY(date)



SELECT * 
FROM [dbo].[v_VaccinatedPop]
-- =================================================================================================================================================================
-- Using Stored Procedures that Accepts a CountryName (Location) and Returns its All -time Mortality rate

IF OBJECT_ID('proc_GetCountryMortalityRate') IS NOT NULL
    DROP PROCEDURE proc_GetCountryMortalityRate
GO

CREATE PROCEDURE proc_GetCountryMortalityRate 
    @CountryName VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE	@TotalCases INT, 
			@TotalDeaths INT, 
			@MortalityRate FLOAT;
    
    SELECT	@TotalCases = SUM(new_cases), 
			@TotalDeaths = SUM(new_deaths)
    FROM	[dbo].[CovidDeaths]
    WHERE	location = @CountryName;
    
    IF			@TotalCases IS NULL OR @TotalCases = 0
    BEGIN
        SET		@MortalityRate = NULL;
    END
    ELSE
    BEGIN
        SET @MortalityRate = ROUND(CAST(@TotalDeaths AS FLOAT) / CAST(@TotalCases AS FLOAT) * 100, 2);
    END
    
    SELECT @MortalityRate AS MortalityRate;
END


EXEC proc_GetCountryMortalityRate  'Tanzania'

--====================================================================================================================================================================
--		  *****							THE END						******
--====================================================================================================================================================================
