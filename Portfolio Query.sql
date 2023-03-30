
---  ================================================================================
---Portfoli Project - SQL Data Exploration
USE [PortfolioProject]
GO

SELECT *
FROM [dbo].[CovidDeaths]

SELECT *
FROM [dbo].[CovidVaccinations]
--DROP TABLE [dbo].[CovidVaccinations]
--================================================================================
--1. Selecting the Data I will be Using
SELECT		[location],
			[date],
			total_cases,
			new_cases,
			total_deaths,
			[population]
FROM		[dbo].[CovidDeaths]
ORDER BY	[location],
			[date]
--==============================================================================================
--2. Total Cases Vs Total Deaths
--This shows the likelihood of dying if you contract covid in a country
SELECT		location,
			date,
			total_cases,
			new_cases,
			total_deaths,
			ROUND(CAST(total_deaths AS FLOAT) / NULLIF(total_cases, 0) * 100, 2) AS mortality_rate
FROM		[dbo].[CovidDeaths]
WHERE		location = 'United States'
ORDER BY	location, 
			date

-- ============================================================================================
--3. Total Cases Population
SELECT		location,
			date,
			total_cases,
			population,
			total_deaths,
			ROUND(CAST(total_cases AS FLOAT) / NULLIF(population, 0) * 100, 2) AS totalCases_perc
FROM		[dbo].[CovidDeaths]
WHERE		location = 'United States'
ORDER BY	location, 
			date

-- ===============================================================================================
--4. Countries with highest Infection rate compared to population 
SELECT		location,
			population,
			MAX(total_cases) highest_infection_count,
			ROUND(CAST(total_cases AS FLOAT) / NULLIF(population, 0) * 100, 2) AS infection_rate
FROM		[dbo].[CovidDeaths]
--WHERE		location = 'United States'
GROUP BY	location,
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
--================================================================================================
--GLOBAL NUMBERS
--Total cases vs deaths acroscc the world
SELECT date,
       SUM(new_cases) AS new_cases_total,
       SUM(new_deaths) AS new_deaths_total,
       ROUND(SUM(ISNULL(CAST(new_deaths AS FLOAT), 0)) / NULLIF(SUM(ISNULL(CAST(new_cases AS FLOAT), 0)), 0) * 100, 2) AS Deathperc
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY Deathperc DESC

---From the Vaccinations Table
SELECT		a.continent,
			a.location,
			a.date,
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

--USING CTE
WITH VaccinatedPop AS (
    SELECT	a.continent,
            a.location,
            a.date,
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
SELECT  *,
        ROUND(CAST(RollingPeopleVaccinated AS DECIMAL(18,6))/CAST(population AS DECIMAL(18,6)) * 100, 2) AS VaccinationRate
FROM    VaccinatedPop 
ORDER BY 1,2,3 DESC


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
			a.date,
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


--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS
DROP VIEW IF EXISTS v_VaccinatedPop
CREATE VIEW v_VaccinatedPop
AS
SELECT date,
       SUM(new_cases) AS new_cases_total,
       SUM(new_deaths) AS new_deaths_total,
       ROUND(SUM(ISNULL(CAST(new_deaths AS FLOAT), 0)) / NULLIF(SUM(ISNULL(CAST(new_cases AS FLOAT), 0)), 0) * 100, 2) AS Deathperc
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY date
GO


SELECT * 
FROM [dbo].[v_VaccinatedPop]
