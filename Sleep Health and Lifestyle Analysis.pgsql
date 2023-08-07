--Identify any columns or fields that contain Null or missing values, which could indicate incomplete or erroneous data.

select * from Sleep
where Person_ID is NULL
or Gender is NULL
or Age is NULL
or Occupation is NULL
or Sleep_Duration is NULL
or Quality_of_Sleep is NULL
or Physical_Activity_Level is NULL
or Stress_Level is NULL
or BMI_Category is NULL
or Blood_Pressure is NULL
or Heart_Rate is NULL
or Daily_Steps is NULL
or Sleep_Disorder is NULL;

--What is the overall distribution of gender and the average age of the individuals in the dataset?

select Gender, count(*) as total_number, round(avg(Age),2) as avg_age
from Sleep
GROUP by Gender;

--What are the different occupations present in the dataset, and how many individuals belong to each occupation?
select Occupation, count(*) as number_of_people
from Sleep
group by Occupation
order by number_of_people desc;

--What is the average sleep duration of the individuals?
SELECT 
    Person_ID, 
    Sleep_Duration,
    ROUND(AVG(Sleep_Duration) OVER (), 2) AS avg_duration,
    Sleep_Duration - ROUND(AVG(Sleep_Duration) OVER (), 2) AS difference
FROM Sleep
order by difference;

-- How would you rate the quality of sleep based on the provided data?
select Gender,Occupation, round(avg(Quality_of_Sleep),2) as avg_quality_of_sleep,
rank() over (order by round(avg(Quality_of_Sleep),2) desc) as rank
from Sleep
group by Gender,Occupation
order by rank;

-- What is the distribution of physical activity levels among the individuals? How stressed are the individuals in the dataset, on average?
select 
case when Physical_Activity_Level between 30 and 45 then 'Beginner'
when Physical_Activity_Level between 46 and 60 then 'Amateur'
when Physical_Activity_Level between 61 and 75 then 'Advanced'
else 'Sportsmen'
end as Classification,
count(*) as number_of_people, round(avg(Stress_Level),2) as avg_stress,
round(avg(Sleep_Duration),2) as avg_duration
from Sleep
group by Classification
order by avg_stress desc;

--What is the rank of each individual's physical activity level within their respective occupation?
 select Person_ID,Physical_Activity_Level, Occupation,
 dense_rank() over(PARTITION by Occupation order by Physical_Activity_Level desc) as Physical_Activity_Rank
 from Sleep
 order by Physical_Activity_Rank;

-- How many individuals fall into each BMI category (e.g., underweight, normal weight, overweight, obese)?
select BMI_Category, count(*) as number_of_people,
round(count(*) *100/sum(count(*)) over(),2) as percentage
from Sleep
group by BMI_Category
order by percentage desc;

-- What is the average heart rate among the individuals?
select Person_ID, Occupation,round(avg(Heart_Rate),2) as avg_heart_rate,
round(avg(Heart_Rate) over(partition by Occupation),2) as avg_heart_rate_in_occupation
from Sleep
group by Person_ID, Occupation, Heart_Rate
order by avg_heart_rate DESC
limit 20;

-- How many individuals have been diagnosed with a sleep disorder?
select Gender, count(*) as number_of_people, Sleep_Disorder, round(avg(Daily_Steps),0) as avg_steps 
from Sleep
group by Gender, Sleep_Disorder
order by avg_steps desc;

-- How does the average stress level change over different age groups?
select Age, round(avg(Stress_Level),2) as avg_stress_level
from Sleep
group by Age
having round(avg(Stress_Level),2) > 5.0
order by avg_stress_level desc;
