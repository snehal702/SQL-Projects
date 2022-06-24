use [Portfolio_Project_Covid_19];

--checking out the downloaded data
select * from [dbo].[CovidDeaths] order by 3, 4 -- 3rd and 4th column -location and date column
--select * from [dbo].[CovidVaccinations] order by 3, 4 -- 3rd and 4th column -location and date column

--selecting the data we are going to use
select location,date,total_cases,new_cases,total_deaths,new_deaths,population  from [dbo].[CovidDeaths] order by 1,2;

--when was the first death recorded in a country
select location,date,total_cases,total_deaths, round((total_deaths/total_cases)*100,2) as DeathPercentage , first_value(date) 
over(partition by year(date),location order by total_deaths ) as first_date from [dbo].[CovidDeaths] 
where total_deaths =1 and continent is not null ;


--looking at total cases v/s total deaths for that country
--shows the likelihood of dying if you contract covid in your country
select location,date,total_cases,total_deaths, round((total_deaths/total_cases)*100,2) as DeathPercentage from [dbo].[CovidDeaths] order by 1,2;
select location,date,total_cases,total_deaths, round((total_deaths/total_cases)*100,2) as DeathPercentage from [dbo].[CovidDeaths] 
where location like '%India%' and continent is not null order by 1,2;


--total cases v/s population
--shows what % of people got covid in a country
select location,date,population,total_cases, (total_cases/population)*100 as InfectedPercentage from [dbo].[CovidDeaths] 
where location like '%States%' and continent is not null order by 1,2;


--shows which countries have high infection rate wrt population
select location,population,max(total_cases),max((total_cases/population)*100) as InfectionRate from [dbo].[CovidDeaths] 
group by location,population order by 4 desc;


--show which country had highest death count wrt population
select location,population,max(cast(total_deaths as int)) from [dbo].[CovidDeaths] where continent is not null
group by location,population order by 3 desc;


--lets break things down by continent (location has info about both countries and continents)
---show which continent had highest cases  rate wrt population 
select location, max(cast(total_cases as int)), round(max((total_cases/population)*100),2) as InfectedRateContinent from [dbo].[CovidDeaths] 
where continent is null
group by location order by 2 desc;

---show whichh continent had highest death cases count  wrt population 
select location, max(cast(total_deaths as int)), max((total_deaths /total_cases)*100) as DeathPercentageContinent from [dbo].[CovidDeaths] where continent is null
group by location order by 2 desc;

select continent, max(cast(total_deaths as int)) as DeathCountContinent from [dbo].[CovidDeaths] 
where continent is not null
group by continent order by 2 desc;

---getting highest confirmed cases by each country in a continent 
select continent,location, max(total_cases) as InfectedCases from [dbo].[CovidDeaths] 
where continent is not null
group by continent, location order by 3 desc;

---getting highest death cases by each countyry in a continent 
select continent,location, max(cast(total_deaths as int)) as DeathCount from [dbo].[CovidDeaths] 
where continent is not null
group by continent, location order by 3 desc;


--Global Numbers
---total cases v/s total deaths and total_new_cases v/s total_new_deaths

select date, sum(total_cases) as total_cases, sum(cast(total_deaths as int)) as DeathCases,
sum(cast(total_deaths as int))/ sum(total_cases) *100 as DeathPer_reportedcases, sum(new_cases) as new_cases, 
sum(cast(new_deaths as int)) new_deaths, sum(cast(new_deaths as int))/sum(new_cases) *100 DeathPer_newcases
from CovidDeaths where continent is not null group by date order by 1 ;


--overall infection rate across the world 
select sum(total_cases) as total_cases, sum(cast(total_deaths as int)) as DeathCases,
sum(cast(total_deaths as int))/ sum(total_cases) *100 as DeathPer_reportedcases, sum(new_cases) as new_cases, 
sum(cast(new_deaths as int)) new_deaths, sum(cast(new_deaths as int))/sum(new_cases) *100 DeathPer_newcases
from CovidDeaths where continent is not null ;

--max infection rate wrt population
select date,max(total_cases) from [dbo].[CovidDeaths] group by date order by 2 desc;

--max death count wrt population
select date,max(cast(total_deaths as int)) from [dbo].[CovidDeaths] where continent is not null group by date
order by 2 desc;


--now lets look at Vaccinations Table
select * from CovidDeaths dea join CovidVaccinations vac on vac.location=dea.location and vac.date=dea.date;

--looking at total population vs vaccinations --number of vaccinations done for that particular day
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations from CovidDeaths dea join CovidVaccinations vac 
on vac.location=dea.location and vac.date=dea.date where dea.continent is not null order by 2,3;


--looking at total vaccinations done till a particular date --rolling sum of new_vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over(partition by dea.location order by dea.location, dea.date) as rolling_total_vaccinations
from CovidDeaths dea join CovidVaccinations vac 
on vac.location=dea.location and vac.date=dea.date where dea.continent is not null order by 2,3;


--looking at total vaccinations done till a particular date --rolling sum of new_vaccinations
with PopvsVac as(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over(partition by dea.location order by dea.location, dea.date) as rolling_total_vaccinations
from CovidDeaths dea join CovidVaccinations vac 
on vac.location=dea.location and vac.date=dea.date where dea.continent is not null )
select *, round((rolling_total_vaccinations/population)*100,2) from PopvsVac -- vaccination rate/population


--to get the max% of popln vaccinated  for a country
drop table if exists #temptable;
create table #temptable(continent nvarchar(100), location nvarchar(100),date datetime, population numeric, new_vaccinations numeric,
rolling_total_vaccinations numeric);
insert into #temptable 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over(partition by dea.location order by dea.location, dea.date) as rolling_total_vaccinations
from CovidDeaths dea join CovidVaccinations vac 
on vac.location=dea.location and vac.date=dea.date where dea.continent is not null

select location,population, max(rolling_total_vaccinations/population*100) from #temptable group by location,population order by location;


--create a view to use the query later for visualization
create view Vaccination_done_till_date as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over(partition by dea.location order by dea.location, dea.date) as rolling_total_vaccinations
from CovidDeaths dea join CovidVaccinations vac 
on vac.location=dea.location and vac.date=dea.date where dea.continent is not null 

select * from Vaccination_done_till_date
