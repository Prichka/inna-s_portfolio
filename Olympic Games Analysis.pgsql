--General check 'athlete' table
SELECT * from athletes
limit 10;

-- Add new columns for Year and Season
ALTER TABLE athletes
ADD COLUMN Year integer,
ADD COLUMN Season text;

-- Update the new columns with split values
UPDATE athletes
SET 
    Year = CAST(SPLIT_PART(Games, ' ', 1) AS integer),
    Season = SPLIT_PART(Games, ' ', 2);
	
--General check 'medal' table
select * from medals
limit 10;

-- Add new columns for Country and Year
ALTER TABLE medals
ADD COLUMN Country text,
ADD COLUMN Year integer;

-- Copy the last 4 digits from SourceColumn to DestinationColumn as integer because format was 'los-angeles-1984'
UPDATE medals
SET year = CAST(RIGHT(slug_game, 4) AS integer);

-- Copy all values except the last 5 characters from SourceColumn to DestinationColumn
UPDATE medals
SET country = LEFT(slug_game, LENGTH(slug_game) - 5);

-- Update the FullName column to capitalize each word
UPDATE medals
SET athlete_full_name = INITCAP(athlete_full_name);


2. General Analysis:

-- How many medals were awarded in each Olympic Games (by year and country where Olympic Games were held)?
select country, year, count(*) as medals_count 
from medals
group by country, year
order by 2 desc;

-- Which Olympic Games had the highest and lowest total medal counts?
with total_medals as(
select country, count(*) as medals_count
from medals
group by country)

select * 
from total_medals
where medals_count= (select max(medals_count) from total_medals)
or 
medals_count= (select min(medals_count) from total_medals);

-- What is the distribution of medal types (gold, silver, bronze) across all Olympic Games?
select medal_type, count(*) as medals_count 
from medals
group by medal_type
order by case when medal_type = 'GOLD' then 1
when medal_type = 'SILVER' then 2
else 3 end;

-- Top 5 countries which have won the most gold medals?
select country_name, country_code,
sum(case when medal_type='GOLD' then 1 else 0 end) as gold_medals
from medals
group by country_name, country_code
order by gold_medals desc
limit 5;

-- What is the trend of gold medal counts for specific countries over time?
select country as olympic_game, year, count(*) as gold_medal_count
from medals
where country_name = 'USA'  -- Replace with the specific country you want to analyze
    and medal_type = 'GOLD'
group by olympic_game, year
order by year;

3. Athlete and Country Analysis:

--Which countries have participated in the most Olympic Games?
select country_name, count (distinct slug_game) as games_participated,
dense_rank() over(order by count (distinct slug_game)desc) as rank
from medals
group by country_name
limit 10;

--Rank countries by the total number of medals won 
with CountryMedalCounts as (
    select country_name, count(*) as total_medals
    from medals
    where medal_type is not null
    group by country_name)

select country_name, total_medals,
rank () over (order by total_medals desc) as medal_rank
from CountryMedalCounts
order by medal_rank;

--What is the total medal count for each country in each Olympic Games?
select country_name, country_code, slug_game, count(*) as total_medals
from medals
group by country_name,country_code, slug_game
order by total_medals desc;

--Top country/s with the total medals in each discipline .
with ranking as(
    select country_name, discipline_title,
    count(*) as total_medals,
    rank() over (partition by discipline_title order by count(*) desc) as rank
from medals
group by discipline_title, country_name)

select country_name, discipline_title,total_medals
from ranking
where rank = 1
order by total_medals desc; 

--What is the mean age, height, and weight of athletes in each Olympic Games?
select Games,
    round(avg(Age),0) as avg_age, 
    round(avg(Height),2) as avg_height, 
    round(avg(Weight),0) as avg_weight
from athletes
group by Games;

--Calculate statistical measures like standard deviation and range of athlete ages, heights, and weights
select round(STDDEV(Age),2) as stddev_age, 
round(STDDEV(Weight),2) as stddev_weight, 
round(STDDEV(Height),2) as stddev_height,
max(Age) as max_age, min(Age) as min_age,
max(Weight) as max_weight, min(Weight) as min_weight,
max(Height) as max_height, min(Height) as min_height
from athletes 
where Age > 0
and Weight > 0
and Height > 0;

-- Calculate correlation coefficient between age and the number of medals won
select corr(Age, medals_count) as age_medals_correlation
from (
    select athletes.Age, count(*) as medals_count
    from athletes
    left join medals 
    on athletes.Name = medals.athlete_full_name
    where medals.medal_type is not null
    group by athletes.Age) as subquery
where Age is not null;

-- Calculate correlation coefficient between weight and the number of medals won
select corr(Weight, medals_count) as weight_medals_correlation
from (
    select athletes.Weight, count(*) as medals_count
    from athletes
    left join medals 
    on athletes.Name = medals.athlete_full_name
    where medals.medal_type is not null
    group by athletes.Weight) as subquery
where Weight is not null;

-- Calculate correlation coefficient between height and the number of medals won
select corr(Height, medals_count) as height_medals_correlation
from (
    select athletes.Height, count(*) as medals_count
    from athletes
    left join medals 
    on athletes.Name = medals.athlete_full_name
    where medals.medal_type is not null
    group by athletes.Height) as subquery
where Height is not null;

--What is the age distribution of medal-winning athletes?
select discipline_title, min(Age) as min_age, max(Age) as max_age, round(avg(Age),0) as avg_age
from athletes
left join medals
on athletes.Name=medals.athlete_full_name
where medal_type is not null
and Age >0
group by discipline_title;

--Who are the top-performing athletes with the most medals?
select Name,Team, Sport, count(slug_game) as total_medals
from athletes
left join medals
on athletes.Name=medals.athlete_full_name
where medal_type is not Null
group by Name, Team, Sport
order by total_medals desc;

--	Are there any athletes who have won medals in multiple Olympic Games?
select "Name", count (distinct slug_game) as total_medals
from athletes
left join medals
on athletes."Name"=medals.athlete_full_name
where medal_type is not null
group by "Name"
HAVING count(distinct slug_game) > 1
order by total_medals desc;

4. Event Analysis

--What is the difference between the total number of participants in the Olympic Games compared to previous Olympic Games?
with participants as (
select year, season, count (Name) as number_of_participants
from athletes
group by year, season)

select year, season, number_of_participants,
number_of_participants - lag (number_of_participants) over (partition by season order by year) as previous_season_participants
from participants
order by year, season;

--What is the gender distribution among athletes in different events?
select Games,
sum(case when Sex='F' then 1 else 0 end) as female_gender_distribution,
sum(case when Sex='M' then 1 else 0 end) as male_gender_distribution
from athletes
group by Games;

--Are there any trends in the number of medals awarded over time?
select year, count(*) number_of_medals
from medals
group by year
order by year;

--Calculate improvement or decline in medal counts over the years
with MedalCounts as (
    select country_name, year, count(*) as total_medals
    from medals
    where medal_type is not null
   group by country_name, year),

MedalChange as (
    select country_name, year, total_medals,
    lag (total_medals) over (partition by country_name order by year) as previous_year_medals
    from MedalCounts)

select mc.country_name, mc.year, mc.total_medals,
    mc.total_medals - mc.previous_year_medals as medal_change
from MedalChange as mc
order by mc.country_name, mc.year;

-- Compare the performance of two or more countries by medal count over multiple Olympic Games.
select slug_game as Olympic_Games, country_name, count(*) as medal_count
from medals
where medal_type is not null 
    and country_name in ('USA', 'Germany') -- we can replace with the countries we want to compare
group by slug_game, country_name
order by slug_game, country_name;

--Which events have the highest and lowest average medal counts per game?
with EventMedalCounts as (
    select event_title, slug_game, count(*) as medal_count
    from medals
    where medal_type is not null
    group by event_title, slug_game),

AverageMedalCounts as (
    select event_title, avg(medal_count) as avg_medal_count_per_game
    from EventMedalCounts
    group by event_title)

select event_title, round(avg_medal_count_per_game,0)
from AverageMedalCounts
order by avg_medal_count_per_game desc, event_title;