
CREATE TABLE book(
	book_id INT PRIMARY KEY AUTO_INCREMENT,
	title VARCHAR(50),
	author VARCHAR(30),
	amount DECIMAL(8,2),
	price INT);

INSERT INTO book (title, author, price, amount)
VALUES ('Белая гвардия', 'Булгаков М.А.','540.50', '5'), ('Идиот', 'Достоевский Ф.М.','460.00', '10'), ('Братья Карамазовы', 'Достоевский Ф.М.','799.01', '2');
SELECT * from book;

--Наприкінці року ціну кожної книги на складі перераховують – знижують її на 30%.
SELECT title, author, amount, ROUND((price*0.7),2) AS new_price FROM book

--Під час аналізу продажів книг з'ясувалося, що найбільшою популярністю користуються книги Михайла Булгакова, на другому місці книги Сергія Єсеніна. 
Тому вирішили підняти ціну книг Булгакова на 10%, а ціну книг Єсеніна - на 5%.
SELECT author, title, 
	ROUND(IF(author='Булгаков М.А.', price*1.1,IF(author='Есенин', price*1.05,price)),2) AS new_price

--Автор, ціна та кількість усіх книг, ціна яких менша за 500 або більше 600, а вартість всіх примірників цих книг більша або дорівнює 5000.
SELECT author, price, amount FROM book
WHERE (price<500 OR price>600) and amount*price>=5000;

--Назва та авторка книг, ціни яких належать інтервалу від 540.50 до 800 (включаючи межі), а кількість або 2, або 3, або 5, або 7.
SELECT title, author, price FROM book
WHERE (price between 540.5 and 800) and amount in(2,3,5,7);
ORDER BY 2, 3

--Назва та автора тих книг, назва яких складається із двох і більше слів, а ініціали автора містять літеру «С».
SELECT title, author FROM book
WHERE title LIKE "_% %" AND (author LIKE "%_.C.%" OR LIKE "%C._.%")
ORDER BY title










	
	










SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 3,4


-- Selecting Data that we are going to start with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in my country

SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 2) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location='Jamaica'
ORDER BY 1,2


-- Total Cases vs Population
-- Shows what percentage of the population got Covid

SELECT location, date, total_cases, population, ROUND((total_cases/population)*100, 5) AS CasesByPopulation
FROM PortfolioProject..CovidDeaths
--WHERE location='Jamaica'
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, ROUND(MAX((total_cases/population))*100,2) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location='Jamaica'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- Countries with Highest Death Count per Population

SELECT Location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Breaking things down by Continent

-- Continents with Highest Death Count per Population

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC



-- Global Numbers by date

SELECT date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS int)) AS TotalDeaths, ROUND((SUM(cast(new_deaths AS int))/SUM(new_cases))*100, 2) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY date
ORDER BY 1,2


-- Global Numbers overall

SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS int)) AS TotalDeaths, ROUND((SUM(cast(new_deaths AS int))/SUM(new_cases))*100, 2) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
--GROUP BY date
ORDER BY 1,2



-- Total Population vs Vaccinations
-- Percentage of Population that has received at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3



-- Using CTE to perform calculation on partition by previous query

WITH PopulationvsVaccinations (Continent, Location, date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, SUM(CONVERT(int,vax.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVax vax
	ON dea.location = vax.location
	and dea.date = vax.date
WHERE dea.continent is NOT NULL 
)
SELECT *, ROUND((RollingPeopleVaccinated/Population)*100,2) AS RollingPercent
FROM PopulationvsVaccinations



--Using TEMP TABLE to perform calculation on Partition By in previous query 

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255), 
date datetime, 
Population numeric, 
New_Vaccinations numeric, 
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, SUM(CONVERT(int,vax.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVax vax
	ON dea.location = vax.location
	and dea.date = vax.date
WHERE dea.continent is NOT NULL 

SELECT *, ROUND((RollingPeopleVaccinated/Population)*100,2) AS RollingPercent
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualisations

CREATE View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, SUM(CONVERT(int,vax.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVax vax
	ON dea.location = vax.location
	and dea.date = vax.date
WHERE dea.continent is NOT NULL 


