select * from information_schema.columns
where table_name='Bank'

1.	customer age analysis
select 
    min(age) as min, 
    round(avg(age),1) as avg,
    max(age) as max, count(*) as number_of_clients
from "Bank";
2.	Job-related and education Analysis:
select 
    education,
    string_agg(distinct job,', ') as jobs
from "Bank"
group by education
order by education desc;
3.	What is the distribution of clients across different job types?
select 
  job,
  count(*) as number_of_clients
  from "Bank"
  group by job
  order by number_of_clients desc;

4.	Percentage of no-default credits per marital
select 
    marital,
    count(*) as number_of_client,
    round(count(case when credit_in_default = 'no' then 1 end)::decimal / count(credit_in_default) * 100,2) as percentage_no_default
from "Bank"
group by marital;
5.	loan portfolio analysis
select 
    sum(case when housing_loan='yes' and personal_loan='yes' then 1 else 0 end ) as both_loans,
    sum(case when housing_loan='yes' and personal_loan !='yes' then 1 else 0 end) as housing_loan,
    sum(case when housing_loan!='yes' and personal_loan='yes' then 1 else 0 end) as personal_loan
from "Bank";
6.	analysis of calls by month and day of the week
select
    month,
    day_of_week,
    count(*) AS number_of_contacts
from "Bank"
group by month, day_of_week
order by
    case
        when month = 'jan' THEN 1
        when month = 'feb' THEN 2
        when month = 'mar' THEN 3
        when month = 'apr' THEN 4
        when month = 'may' THEN 5
        when month = 'jun' THEN 6
        when month = 'jul' THEN 7
        when month = 'aug' THEN 8
        when month = 'sep' THEN 9
        when month = 'oct' THEN 10
        when month = 'nov' THEN 11
        when month = 'dec' THEN 12
    END,
    day_of_week;

7.	the most successful days in each month дозвон
with MonthlySuccess as (
    select
        month,
        day_of_week,
        count(*) AS total_contacts,
        sum(case when poutcome = 'success' then 1 else 0 end) as successful_contacts,
        rank() over (partition by month order by (sum(case when poutcome = 'success' then 1 else 0 end)::decimal / count(*)) desc) as rank_success
    from "Bank"
    group by month, day_of_week
)

select
    month,
    day_of_week,
    round((successful_contacts::decimal / total_contacts) * 100,2) as success_percentage
from MonthlySuccess
where rank_success = 1
order by success_percentage desc;

8.	the most successful days - terms deposit
with DaySuccess as (
    select
        day_of_week,
        count(*) AS total_contacts,
        sum(case when term_deposit_subscribe = 'yes' then 1 else 0 end) as successful_campaign,
        rank() over (partition by day_of_week order by (sum(case when term_deposit_subscribe = 'yes' then 1 else 0 end)::decimal / count(*)) desc) as rank_success
    from "Bank"
    group by day_of_week
)

select
    day_of_week,
    round((successful_campaign::decimal / total_contacts) * 100,2) as success_percentage
from DaySuccess
where rank_success = 1
order by success_percentage desc;

9.	avg duration time per contact and success.  Is there a correlation between the communication mode and the subscription outcome?

select 
    contact,
    round(avg(duration)) as avg_duration,
    round(sum(case when term_deposit_subscribe='yes' then 1 else end)::decimal/count(*)*100 ,1) as per_successfull_campaign
from "Bank"
group by contact;

9. Number of contacts performed during this campaign.
select 
    campaign,
    count(*) as number_of_clients,
    round(avg(duration)) as avg_duration
from "Bank"
group by campaign
order by campaign desc;

10. Can you identify the top 10 clients with the longest duration of the last contact? Success?
select
    age,
    education,
    job,
    marital,
    campaign,
    duration,
    term_deposit_subscribe
from "Bank"
order by duration desc
limit 10;

11. What is the distribution of days since the client was last contacted?
select
    days_from_last_contact,
    count(*) AS frequency,
    (count(*)::decimal / (select count(*) from "Bank")) * 100 AS percentage
from "Bank"
group by days_from_last_contact
order by days_from_last_contact;


How does the subscription rate vary among different marital statuses?
select 
    marital,
    round(sum(case when term_deposit_subscribe='yes' then 1 else 0 end)::decimal/count(*)*100) as success_percentage
from "Bank"
group by marital
order by success_percentage desc;
