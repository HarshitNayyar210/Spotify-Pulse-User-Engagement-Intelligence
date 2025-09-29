--Retention Rate Calculation

Create view Retention_Rate_Percentage as
Select cast(SUM(case when is_churned = 0 then 1 else 0 end) as Float) * 100 / COUNT(user_id) as Retention_Rate_Percentage
from [SpotifyData ]

--Advanced Segmentation: What is the average listening_time and songs_played_per_day for each combination of subscription_type and device_type?

create view avg_time as 
Select subscription_type, device_type, AVG(listening_time) as avg_listening_type, AVG(songs_played_per_day) as Avg_songs_played_per_day
from Spotify_Data
group by subscription_type, device_type

--Geographic & Subscription Analysis: Find the churn rate for each subscription_type within the top 3 countries by user count.

create view Churn_rate_for_top_3_countries as
With top_3_countries as (
Select t1.country, COUNT(t1.user_id) as Toal_User_Count
from ProtfolioProject2..[Spotify_Data ] t1
Group by t1.country
)

Select t1.country, t1.subscription_type, CAST(sum(t1.is_churned) as float) * 100 / COUNT(t1.user_id) as Churn_rate_per_country
from ProtfolioProject2..[Spotify_Data ] t1
	join top_3_countries t2
	on t1.country = t2.country
group by t1.country, t1.subscription_type

--User Behavior Impact: Identify the percentage of churned users that fall into the Low Ads and High Ads categories. What does this suggest about the impact of ads on churn?

create view User_behavior_Impact as
Select t1.[Ad-Rate], cast(sum(t1.is_churned) as float) * 100 / COUNT(t1.user_id) as Churn_Rate_by_Ads
from [Spotify_Data ] t1
where t1.[Ad-Rate] <> 'No Ads'
Group by t1.[Ad-Rate]

--Window Function Challenge: Using a window function, rank the subscription_type within each country based on the highest average engagement_score.

Create view Subscription_Type_ranking as 
Select country, subscription_type, avg(Engagement_Rate) as Avg_Engagement_Score_Per_Country, 
		RANK() over (Partition by country order by avg(Engagement_Rate) desc) as Country_ranking
from [Spotify_Data ] 
Group by country, subscription_type

--Subquery for Comparison: Find all Female users whose skip_rate is higher than the average skip_rate for all Male users.

create view Female_users_with_high_skip_rate as
Select sd.user_id, sd.gender, sd.skip_rate
    from [Spotify_Data ] sd
        where sd.gender = 'Female' and sd.skip_rate > (
                        Select AVG(skip_rate)
                        from [Spotify_Data ]
                        where gender = 'Male'
                        )


--Churn Propensity Score: Develop a query that assigns a churn_risk_level (Low, Medium, High) to each user based on a combination of their listening_time, songs_played_per_day, and skip_rate.

Create view churn_risk_level as 
SELECT
    user_id,
    listening_time,
    songs_played_per_day,
    skip_rate,
    CASE
        -- High risk: Low listening time, few songs played, high skip rate.
        WHEN listening_time < 50 AND songs_played_per_day < 20 AND skip_rate > 0.4 THEN 'High'
        -- Medium risk: Average listening time, average songs played, medium skip rate.
        WHEN (listening_time BETWEEN 50 AND 150) OR (songs_played_per_day BETWEEN 20 AND 50) OR (skip_rate BETWEEN 0.2 AND 0.4) THEN 'Medium'
        -- Low risk: High listening time, many songs played, low skip rate.
        WHEN listening_time > 150 AND songs_played_per_day > 50 AND skip_rate < 0.2 THEN 'Low'
        ELSE 'Undetermined' -- For users who don't fit into any of the above categories.
    END AS churn_risk_level
FROM
    [Spotify_Data];

--Date-Based Analysis: Assuming a standard 30-day month, how many users in the Free subscription tier are expected to churn in the next month, based on the historical churn rate for that group?

create view free_churning_status as 
Select sd.user_id, sd.subscription_type, cl.churn_risk_level
from churn_risk_level cl
    join [Spotify_Data ] sd
    on cl.user_id = sd.user_id
where sd.subscription_type = 'Free' and cl.churn_risk_level = 'High'

--Data Aggregation: Create a summary table that shows the total number of users, total number of churned users, and the churn rate for each age_group and subscription_type combination.

create view summary_table as
Select sd.age_demographics, sd.subscription_type, COUNT(sd.user_id) as Total_users, 
        cast(sum(sd.is_churned) as float) as Churned_users, cast(sum(sd.is_churned) as float) * 100/ 
        COUNT(sd.user_id) as Churn_Percentage
from [Spotify_Data ] sd
group by sd.Age_Demographics, sd.subscription_type


--The End. Thankyou!