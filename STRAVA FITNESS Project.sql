# Strava_fitness - Bellabeat Analysis #

Create schema STRAVA_FITNESS; 

# Table Creation #

Create table dailyActivity_merged (
Id bigint,
Region varchar(20),
ActivityDate Date,
TotalSteps INT,
TotalDistance_Kms FLOAT,
TrackerDistance_Kms FLOAT,
LoggedActivitiesDistance_Kms FLOAT,
VeryActiveDistance_Kms FLOAT,
ModeratelyActiveDistance_Kms FLOAT,
LightActiveDistance_Kms FLOAT,
SedentaryActiveDistance_Kms FLOAT,
VeryActiveMinutes INT,
FairlyActiveMinutes INT,
LightlyActiveMinutes INT,
SedentaryMinutes INT,
Calories INT
);

Create table dailyCalories_merged (
Id bigint,
Region varchar(20),
ActivityDate date,
Calories INT
);

Create table dailyIntensities_merged (
Id bigint,
Region varchar(20),
ActivityDate	date,
SedentaryMinutes INT,
LightlyActiveMinutes INT,
FairlyActiveMinutes INT,
VeryActiveMinutes INT,
SedentaryActiveDistance_Kms	FLOAT,
LightActiveDistance_Kms FLOAT,
ModeratelyActiveDistance_Kms FLOAT,
VeryActiveDistance_Kms FLOAT
);

Create table dailySteps_merged (
Id bigint,
Region varchar(20),
ActivityDate date,
StepTotal INT
);

 Create table heartrate_seconds_merged (
Id bigint,
Time datetime,
Value Int
);

Create table hourlyCalories_merged (
Id bigint,
Region Varchar(20),
ActivityHour datetime,
Calories INT
);

Create table hourlyIntensities_merged (
Id bigint,
Region Varchar(20),
ActivityHour datetime,
TotalIntensity INT,
AverageIntensity int
);

Create table hourlySteps_merged (
Id bigint,
ActivityHour datetime,
StepTotal Int
);

Create table minuteCaloriesNarrow_merged (
Id bigint,
ActivityMinute datetime,
Calories Int
);

Create table minuteIntensitiesNarrow_merged (
Id bigint,
ActivityMinute datetime,
Intensity INT
);

Create table minuteMETsNarrow_merged (
Id bigint,
ActivityMinute datetime,
METs INT
);

Create table minuteSleep_merged (
Id bigint,
date datetime,
value int,
logId BIGINT --  Changed from INT to BIGINT as INT cannot handle large numbers.
);

Create table minuteStepsNarrow_merged (
Id bigint,
ActivityMinute datetime,
Steps INT
);

Create table sleepDay_merged (
Id bigint,
SleepDay datetime,
TotalSleepRecords INT,
TotalMinutesAsleep int,
TotalTimeInBed Int
);

Create table weightLogInfo_merged (
Id bigint,
Date datetime,
WeightKg bigint,
WeightPounds bigint,
Fat INT,
BMI bigint,
IsManualReport boolean,
LogId bigint --  Changed from INT to BIGINT as INT cannot handle large numbers.
);

load data infile 'minuteStepsNarrow_merged.csv'
into table minuteStepsNarrow_merged
fields terminated by','
enclosed by '"'
Lines terminated by '\n'
ignore 1 lines
(Id, ActivityMinute, Steps)
set Id = NULLIF(Id, '');

show variables like "secure_file_priv";

show variables like 'local_infile';

set global local_infile=1; -- To insert the file directly from the path.

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/weightLogInfo_merged.csv'
into table weightloginfo_merged
fields terminated by','
enclosed by '"'
Lines terminated by '\n'
ignore 1 lines
(Id, Date, WeightKg, WeightPounds, Fat, BMI, @IsManualReport, LogId)
set IsManualReport = case
                        when @IsManualReport = 'TRUE' THEN 1
                        when @IsManualReport = 'FALSE' THEN 0
                        else null
                      End; -- To upload the file that is not accepting the True and False value as it is.


Select Count(*) from dailyactivity_merged; -- =========== # to cross check all the table count with actual Csv.

-- Join table creation

Create table daily_joined_final as -- Create and Join the tables
select 
  a.Id,
  a.Region,
  a.ActivityDate,
  a.TotalSteps,
  a.TotalDistance_Kms,
  a.Calories as DailyCalories,
  b.Calories as ExtraCalories,
  c.SedentaryMinutes,
  c.LightlyActiveMinutes,
  c.FairlyActiveMinutes,
  c.VeryActiveMinutes,
  c.SedentaryActiveDistance_Kms,
  c.LightActiveDistance_Kms,
  c.ModeratelyActiveDistance_Kms,
  c.VeryActiveDistance_Kms,
  s.TotalMinutesAsleep,
  w.WeightKg,
  w.BMI
from 
  dailyActivity_merged a
left join
  dailyCalories_merged b 
  on a.Id = b.Id and a.ActivityDate = b.ActivityDate
left join
  dailyIntensities_merged c 
  on a.Id = c.Id and a.ActivityDate = c.ActivityDate
left join
  sleepday_merged s 
  on a.Id = s.Id and a.ActivityDate = s.SleepDay
left join
  weightloginfo_merged w 
  on a.Id = w.Id and a.ActivityDate = w.Date;


Select count(*) From daily_joined_final; 
 

Select * From daily_joined_final
Limit 5;

Create table hourly_activity_final as -- Create and Join the tables
select 
	s.Id,
    d.Region, -- pulling Region from dailyactivity_merged table
    s.ActivityHour,
    s.StepTotal,
    c.Calories,
    i.TotalIntensity,
    i.AverageIntensity
From 
hourlysteps_merged s
left join hourlycalories_merged c
	on s.Id = c.Id and s.ActivityHour = c.ActivityHour
left join hourlyIntensities_merged i
	on s.Id = i.Id and s.ActivityHour = i.ActivityHour
left join dailyactivity_merged d
	on s.Id = d.Id and date(s.ActivityHour) = d.Activitydate;

Select * From hourly_activity_final;



-- ==================================== Analysis ====================================

-- 1 - Total Usage by Region

Select
	Region,
	Sum(TotalSteps) as Total_Steps,
    sum(TotalDistance_Kms) as Total_distance,
    sum(DailyCalories) as Tota_calories,
    Avg(LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes) as AvgActiveMinutes
From
	daily_joined_final
Group By
	Region;
    
-- 2 - Top 10 Users

Select
	Id,
    Region,
	Sum(TotalSteps) as Total_Steps
From 
	daily_joined_final
Group By 	
	Id, Region
Order By
	Total_Steps Desc -- with asc, can be shown bottom performing as well.
Limit 10;

-- 3 - Bottom performing Region

Select
    Region,
	Sum(TotalSteps) as Total_Steps
From 
	daily_joined_final
Group By 	
	Region
Order By
	Total_Steps asc
Limit 1;

-- 4 - Total Usage

Select
	Sum(TotalSteps) as Total_Steps,
    sum(TotalDistance_Kms) as Total_distance,
    sum(DailyCalories) as Tota_calories,
    sum(LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes) as Total_ActiveMinutes
From
	daily_joined_final; -- This gives overall usage among the demographics like - (TotalSteps, TotalDistance_Kms, DailyCalories, Total_ActiveMinutes)

-- 5 - Highest usage (overall / Monthly trend) 
-- Total Usage by date

Select
	ActivityDate,
	Sum(TotalSteps) as Total_Steps,
    sum(TotalDistance_Kms) as Total_distance,
    sum(DailyCalories) as Tota_calories,
    sum(LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes) as Total_ActiveMinutes
From
	daily_joined_final
Group By 
	ActivityDate
Order By
	Total_Steps desc, Total_distance desc, Tota_calories desc, Total_ActiveMinutes desc
Limit 1;
	
-- Total Usage by region

Select
	Region,
	Sum(TotalSteps) as Total_Steps,
    sum(TotalDistance_Kms) as Total_distance,
    sum(DailyCalories) as Tota_calories,
    sum(LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes) as Total_ActiveMinutes
From
	daily_joined_final
Group By 
	Region
Order By
	Region;

-- Total Usage by Monthly Trend

Select
	month(ActivityDate) as Monthnum,
	Sum(TotalSteps) as Total_Steps,
    sum(TotalDistance_Kms) as Total_Distance,
    sum(DailyCalories) as Tota_Calories,
    sum(LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes) as Total_ActiveMinutes
From
	daily_joined_final
Group By 
	MonthNum
Order By
	MonthNum;

-- 6 - Average Active time

Select
	avg(LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes) as Avg_ActiveMinutes -- combined all activities
From
	daily_joined_final;
    
-- 7 - Usage trend (6 months)

Select
	date_format(ActivityDate, '%Y,%m') As MonthYear,
    Sum(TotalSteps) as Total_Steps,
    sum(TotalDistance_Kms) as Total_Distance,
    sum(DailyCalories) as Tota_Calories,
    sum(LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes) as Total_ActiveMinutes
From
	daily_joined_final
group by MonthYear
Order By MonthYear
Limit 6;

-- Usage trend Weekly

Select
	DAYNAME(ActivityDate) As DayOfWeek,
    Sum(TotalSteps) as Total_Steps,
    sum(TotalDistance_Kms) as Total_Distance,
    sum(DailyCalories) as Tota_Calories,
    sum(LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes) as Total_ActiveMinutes
From
	daily_joined_final
group by 
	DayOfWeek
Order By 
	field(DayOfWeek, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

-- Hourly Usage

Select
	Hour(ActivityDate) As HourOfDay,
    Sum(TotalSteps) as Total_Steps,
    sum(TotalDistance_Kms) as Total_Distance,
    sum(DailyCalories) as Tota_Calories,
    sum(LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes) as Total_ActiveMinutes
From
	daily_joined_final
group by 
	HourOfDay
Order By
	HourOfDay;

-- 8 - Top/bottom performing month (Also, Region can be added)
-- Top performing Month

Select
	Region,
	date_format(ActivityDate, '%Y,%m') As MonthYear,
    Sum(TotalSteps) as Total_Steps,
    sum(TotalDistance_Kms) as Total_Distance,
    sum(DailyCalories) as Tota_Calories,
    sum(LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes) as Total_ActiveMinutes
From
	daily_joined_final
group by 
	Region, MonthYear
Order By 
	Total_ActiveMinutes desc, Total_Steps desc, Total_Distance desc, Tota_Calories desc
Limit 1;

-- Bottom performing Month

Select
	date_format(ActivityDate, '%Y,%m') As MonthYear,
    Sum(TotalSteps) as Total_Steps,
    sum(TotalDistance_Kms) as Total_Distance,
    sum(DailyCalories) as Tota_Calories,
    sum(LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes) as Total_ActiveMinutes
From
	daily_joined_final
group by 
	MonthYear
Order By 
	Total_ActiveMinutes asc, Total_Steps asc, Total_Distance asc, Tota_Calories asc 
Limit 1;

-- 9 - Weekly Distance consistency 

Select
	Id,
    DAYNAME(ActivityDate) As DayOfWeek,
	sum(VeryActiveDistance_Kms + ModeratelyActiveDistance_Kms + LightActiveDistance_Kms + SedentaryActiveDistance_Kms) as Total_ActiveDistance_Kms
from 
	daily_joined_final
Group By
	Id , DayOfWeek
Order By 
	Total_ActiveDistance_Kms desc
Limit 10; 

-- 10 - Intensity trend

Select
	Id,
	DAYNAME(ActivityHour) As DayOfWeek,
	Sum(TotalIntensity) as Total_Intensity
from 
	hourly_activity_final
where
TotalIntensity is not null 				-- To remove null values
Group By
	Id, DayOfWeek
Order by 
    Total_Intensity desc;

-- 11 - Average daily steps

Select
	DAYNAME(ActivityDate) As DayOfWeek,
	Avg(TotalSteps) as Avg_TotalSteps
From
	daily_joined_final
Group By
	DayOfWeek
Order By
	Avg_TotalSteps desc;

-- 12 - Duration

Select
	Id,
    date(ActivityHour) as ActivityDate,
    count(*) as ActiveHours
From
	hourly_activity_final
where
		StepTotal > 0 -- Only hours with activity
Group By
	 Id, ActivityDate
Order By
	ActiveHours desc;

-- 13 Most Active Time of Day - time-based patterns(Also Region wise)
-- 	time-based patterns

Select
    Hour(ActivityHour) As HourOfDay,
    sum(StepTotal) as Total_Step
From
	hourly_activity_final
Group By
	HourOfDay
Order By
	Total_Step Desc
Limit 1;

-- time-based patterns Region wise

Select
	d.Region,
    Hour(ActivityHour) as HourOfDay,
    sum(StepTotal) as Total_Step
From
	hourly_activity_final h
Join 
	daily_joined_final d
on h.Id = d.Id
Group By
	d.Region, HourOfDay
Order By
	d.Region, Total_Step Desc;

-- 14 - Highest calorie, steps, distance, intensity region wise overall/monthly trend

Select
	d.Region,
    month(d.ActivityDate) as MonthNum,
	Sum(c.Calories) as Total_Calories,
    sum(c.StepTotal) as Total_Steps,
    avg(c.AverageIntensity) as Avg_Intensity,
    sum(d.TotalDistance_Kms) Total_Distanceas
from
	hourly_activity_final c
Join
	daily_joined_final d
    on c.Id = d.Id and date(c.ActivityHour = d.ActivityDate)
Group By
	d.Region, MonthNum
Order By
	d.Region, MonthNum;
    
-- 15 - Sleep quality vs. activity levels 

Select
	c.Id,
	c.ActivityDate,
	d.SleepDay,
	d.TotalMinutesAsleep,
	d.TotalTimeInBed,
	c.TotalSteps,
	c.TotalDistance_Kms,
	c.DailyCalories,
	(c.VeryActiveMinutes + c.FairlyActiveMinutes + c.LightlyActiveMinutes) as TotalActiveMinutes
from
	daily_joined_final c
join
	sleepday_merged d
on c.Id = d.Id and c.ActivityDate = d.SleepDay
order by
	d.TotalMinutesAsleep desc;

-- 16 Weight trend vs. activity / calories 

Select
	c.Id,
	c.ActivityDate,
	w.Date AS WeightDate,
	w.WeightKg,
	w.WeightPounds,
	w.BMI,
	c.TotalSteps,
	c.TotalDistance_Kms,
	c.DailyCalories,
	(c.VeryActiveMinutes + c.FairlyActiveMinutes + c.LightlyActiveMinutes) AS TotalActiveMinutes
from
	daily_joined_final c
Join
	weightloginfo_merged w
	on c.Id = w.Id and c.ActivityDate = w.Date
ORDER BY
	w.Date desc;

-- Sleep Quality vs. Activity Levels

Select
  c.Id,
  c.ActivityDate,
  d.SleepDay,
  d.TotalMinutesAsleep,
  d.TotalTimeInBed,
  c.TotalSteps,
  c.TotalDistance_Kms,
  c.DailyCalories,
  (c.VeryActiveMinutes + c.FairlyActiveMinutes + c.LightlyActiveMinutes) AS TotalActiveMinutes
from
  daily_joined_final c
Join
  sleepday_merged d
  on c.Id = d.Id and c.ActivityDate = d.SleepDay;
  
-- Weight Trend vs. Activity/Calories 

Select
	c.Id,
	c.ActivityDate,
	w.Date as WeightDate,
	w.WeightKg,
	w.WeightPounds,
	w.BMI,
	c.TotalSteps,
	c.TotalDistance_Kms,
	c.DailyCalories,
	(c.VeryActiveMinutes + c.FairlyActiveMinutes + c.LightlyActiveMinutes) AS TotalActiveMinutes
from
	daily_joined_final c
Join
	weightloginfo_merged w
    on c.Id = w.Id and c.ActivityDate = w.Date