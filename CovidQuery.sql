/* 
Covid-19 Data Exploration - Data obtained from https://ourworldindata.org/covid-deaths

Skills used: Joins, CTEs, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


-- Basic query to grab all data from CovidDeaths.xlsx
-- order by: Sort by column 3 and then column 4
Select *
From PortfolioProject.dbo.CovidDeaths
order by 3,4


-- After initial review of data, we see that a Continent value can be 'NULL' 
-- where the actual value of the Continent is in the Location column.
-- We can separate and review the differences of the data with and without the 'NULL' value.

Select *
From PortfolioProject.dbo.CovidDeaths
Where continent is not null
order by 3,4

Select *
From PortfolioProject.dbo.CovidDeaths
Where continent is null
order by 3,4


-- Select Data that we are going to be starting with: Location (Countries).

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject.dbo.CovidDeaths
Where continent is not null
order by 1,2


-- Select Data that we are going to be starting with: Location (Continents).
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject.dbo.CovidDeaths
Where continent is null
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid by Location (Countries).
-- Create new column with Alias DeathPercentage

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject.dbo.CovidDeaths
Where continent is not null
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid by Location (Continents).
-- Create new column with Alias DeathPercentage

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject.dbo.CovidDeaths
Where continent is null
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in the United States
-- Create new column with Alias DeathPercentage

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject.dbo.CovidDeaths
Where continent is not null
and location like '%state%'
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of Population is infected with Covid by Location (Countries).

Select location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject.dbo.CovidDeaths
Where continent is not null
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of Population is infected with Covid by Location (Continents).

Select continent, location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject.dbo.CovidDeaths
Where continent is null
order by 1,2,3


-- Total Cases vs Population
-- Shows what percentage of Population is infected with Covid in the United States.

Select location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject.dbo.CovidDeaths
Where location like '%state%'
order by 1,2


-- Location (Countries) with the Highest Infection Rate compared to the Population.
-- MAX only grabs the highest value.

Select location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopInfected
From PortfolioProject.dbo.CovidDeaths
Where continent is not null
Group by Location, population
order by PercentPopInfected desc


-- Location (Continents) with the Highest Infection Rate compared to the Population.
-- This information includes Location (Income Levels)
-- MAX only grabs the highest value.

Select location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopInfected
From PortfolioProject.dbo.CovidDeaths
Where continent is null
Group by Location, population
order by PercentPopInfected desc


-- Location (Countries) with Highest Death Count per Population.

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject.dbo.CovidDeaths
Where continent is not null
Group by location
order by TotalDeathCount desc


-- Location (Continents) with Highest Death Count per Population.
-- Information includes Location (Income Levels).

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject.dbo.CovidDeaths
Where continent is null
Group by location
order by TotalDeathCount desc


-- Continent with Highest Death County per Population.
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject.dbo.CovidDeaths
Where continent is not null
Group by continent
order by TotalDeathCount desc


/*
Global Numbers
*/

-- Looking at total cases and total deaths by date.

Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
	(SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
From PortfolioProject.dbo.CovidDeaths
Where continent is not null
Group by date
order by 1,2


-- Looking at total cases vs total deaths.

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
	(SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
From PortfolioProject.dbo.CovidDeaths
Where continent is not null
order by 1,2


-- Total Population vs Total Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine.
-- Joining CovidDeaths and CovidVaccinations data tables.

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3


-- Using CTE to perform Calculation on Partition in previous query.

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac
order by 1,2,3


-- Using Temp Table to perform Calculation on Partition By in previous query.

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualations.
-- Permanent table created, not a TEMP table.

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 