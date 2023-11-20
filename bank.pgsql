The follwing query returns a comprehensive list of columns and their associated metadata for the "Bank" table. 
It's useful for understanding the structure and characteristics of the table, including data types and constraints on each column.

select 
    column_name, 
    data_type
from information_schema.columns
where table_name='Bank'

age: Age of the client.
job: Type of job the client holds.
marital: Marital status of the client.
education: Client's education level.
credit_in_default: Indicates if the client has credit in default.
housing_loan: Indicates if the client has a housing loan.
personal_loan: Indicates if the client has a personal loan.
contact: Type of communication mode used for contact.
day: Day of the last contact.
month: Month of the last contact.
duration: Duration of the last contact in seconds.
campaign: Number of contacts performed during this campaign.
d_last_contact: Days since the client was last contacted from a previous campaign (999 indicates the client was not contacted).
n_contacts: Number of contacts before this campaign.
poutcome: Outcome of the previous marketing campaign.
term_deposit_subscribe: Indicates if the client subscribed to a term deposit.

**Let's begin with an analysis of the customer age:**
```
select 
    min(age) as min, 
    round(avg(age),1) as avg,
    max(age) as max, count(*) as number_of_clients
from "Bank";
```
The results provide key statistical measures for customer age in the "Bank" dataset. 
The youngest customer is 17 years old, the maximum age of the customer is 98, and the average age is 40.
In addition, we learned that 41188 people participated in the marketing campaign.


The following query groups the data by education and concatenates the distinct job titles within each education group 
using a comma-separated list:
select 
    education,
    string_agg(distinct job,', ') as jobs
from "Bank"
group by education
order by education desc;

The analysis reveals the diversity of job roles across different education levels.
Identifying common job types within each education category can aid in targeted marketing or outreach strategies.


What is the distribution of clients across different job types?
select 
  job,
  count(*) as number_of_clients
  from "Bank"
  group by job
  order by number_of_clients desc;

The analysis provides a clear picture of the job distribution among clients targeted in the bank campaign.
Admin, blue-collar, and technician roles have the highest representation.
These insights assist in identifying potential trends or patterns related to job roles and their impact on campaign success.
The results can inform future marketing strategies, allowing for more targeted and effective outreach efforts.


Percentage of No-Default Credits per Marital Status:
select 
    marital,
    count(*) as number_of_client,
    round(count(case when credit_in_default = 'no' then 1 end)::decimal / count(credit_in_default) * 100,2) as percentage_no_default
from "Bank"
group by marital;

The analysis provides insights into the relationship between marital status and the likelihood of having no default credits.
Single clients have the highest percentage of no-default credits (87.16%), followed by divorced, married, and unknown marital status.


Loan portfolio analysis:
select 
    sum(case when housing_loan='yes' and personal_loan='yes' then 1 else 0 end ) as both_loans,
    sum(case when housing_loan='yes' and personal_loan !='yes' then 1 else 0 end) as housing_loan,
    sum(case when housing_loan!='yes' and personal_loan='yes' then 1 else 0 end) as personal_loan
from "Bank";

Bank can develop targeted marketing strategies for clients with specific loan combinations.
There is a substantial number of clients with only housing loans (17885). 
Compared to Housing Loan, a small number of clients have only Personal Loan (2557) or both loans (3691)


It's time to analyze the effectiveness of the campaign.
Calls by Month and Day of the Week:
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

The results provide the number of contacts for each month and day of the week.
The campaign has been running from March till December.
There seems to be variation in contact frequency, with certain months and days experiencing higher or lower contact volumes.
There are no clear trends in contact patterns.


However, not every call made was successful. Let's analyze most successful days in each month (Dialing Success Percentage)
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

Knowing the most successful days in each month allows for optimized scheduling of marketing campaigns.
It assists in allocating resources effectively on days with higher success probabilities.
The highest number of successful calls were made on Tuesdays in September (31.36%) compared to May when only 2.16% of calls were successful on Mondays.


Let's dive deeper into call analysis. On what days of the week did clients most often agree to open a deposit?
with DaySuccess as (
    select
        day_of_week,
        (select count(*) AS total_contacts from "Bank"
        where term_deposit_subscribe = 'yes'),
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

The success percentage is based on the ratio of successful term deposit subscriptions to total contacts for each day of the week.
The results provide actionable information for targeting specific days to maximize campaign success.
Despite successful calls, only 18.23% of clients agreed to make a deposit on Fridays, 
while on Thursdays 22.52% wanted to open a new deposit.


Subscription Rate Variation Among Marital Statuses:
select 
    marital,
    round(sum(case when term_deposit_subscribe='yes' then 1 else 0 end)::decimal/count(*)*100) as success_percentage
from "Bank"
group by marital
order by success_percentage desc;

Understanding the subscription rate variation among marital statuses helps in tailoring marketing strategies for different demographic groups.
However, there was no significant difference between clients with different marital statuses.


Average Duration Time and Success Percentage by Communication Mode:
select 
    contact,
    round(avg(duration)) as avg_duration,
    round(sum(case when term_deposit_subscribe='yes' then 1 else 0 end)::decimal/count(*)*100 ,1) as per_successfull_campaign
from "Bank"
group by contact;

The correlation between communication mode and subscription success provides insights into the effectiveness of different communication channels.
Cellular communication tends to have a higher success percentage (14.7%) compared to telephone communication (5.2%).
Understanding the average duration time per contact helps assess the level of engagement during conversations.
The average duration time for cellular communication is slightly higher (264 seconds) than that for telephone communication (249 seconds).


Campaign Analysis - Number of calls:
select 
    campaign,
    count(*) as number_of_clients,
    round(avg(duration)) as avg_duration
from "Bank"
group by campaign
order by campaign desc;

I were surprised to find that some clients were contacted more than 40 times for this marketing campaign.
An absolute record is 56 calls to one client! Perhaps we should analyze why there were so many repeat calls and how effectively this time was used.


Top 10 Clients with Longest Duration of Last Contact and Success:
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

Identifying clients with long contact durations can offer insights into potential high-engagement interactions.
Out of the 10 longest conversations, only 3 clients agreed to a deposit.
Therefore, a long conversation with a client cannot always lead to a successfully completed transaction.


Distribution of Days Since Last Contact:
select
    days_from_last_contact,
    count(*) AS frequency,
    (count(*)::decimal / (select count(*) from "Bank")) * 100 AS percentage
from "Bank"
group by days_from_last_contact
order by days_from_last_contact;

Examining the distribution of days since the last contact helps in assessing the recency of client engagements.
96.32% of clients participated in a marketing campaign for the first time.


Conclusion: 
The analysis of the "Bank" dataset offers valuable insights into the characteristics and outcomes of a direct marketing campaign 
conducted by a Portuguese banking institution. Key findings include a diverse customer age range with an average of 40 years, 
prevalent job roles in administration, blue-collar, and technician positions, and a noteworthy distribution of loan portfolios among clients. 
The analysis of contact frequency across months and days of the week provides a basis for optimizing future campaign scheduling. 
Additionally, success percentages related to communication modes and marital statuses shed light on factors influencing subscription outcomes. 
Overall, this comprehensive analysis equips the banking institution with actionable insights to enhance targeting strategies, improve campaign efficiency, 
and refine communication approaches for future marketing endeavors.
