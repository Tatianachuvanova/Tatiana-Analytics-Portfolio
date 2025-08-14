/*
Bellabeat / Fitbit – Analysis SQL
Author: Tatiana Chuvanova
Context: Queries used in the Bellabeat smart device (Fitbit) capstone analysis.
Warehouse: Google BigQuery
Dataset: `steel-spark-430803-r3.Bellabeat_case`
Notes:
- Column names with spaces are quoted using backticks.
- Replace the dataset path with yours if different.
*/

/* -----------------------------------------------------------
   0) QUICK SCHEMA REFERENCE (tables used)
   -----------------------------------------------------------
   - daily_activity
   - daily_calories
   - daily_intensities
   - daily_steps
   - sleep_day
*/

/* -----------------------------------------------------------
   1) CONSISTENCY CHECKS BETWEEN TABLES
   Purpose: Ensure that daily_* tables align by Id and Activity Date.
----------------------------------------------------------- */

/* 1.1) calories vs activity (row-wise match by Id + date) */
SELECT
  activity.Id,
  activity.date AS activity_date,
  activity.calories     AS activity_calories,
  calories.calories     AS calories_table_calories
FROM `steel-spark-430803-r3.Bellabeat_case.daily_activity` AS activity
JOIN `steel-spark-430803-r3.Bellabeat_case.daily_calories` AS calories
  ON activity.Id = calories.Id
 AND activity.date = calories.`activity day`
LIMIT 100;

/* 1.2) steps vs activity */
SELECT
  activity.Id,
  activity.date AS activity_date,
  activity.totalsteps AS activity_total_steps,
  steps.`step total`  AS steps_table_total
FROM `steel-spark-430803-r3.Bellabeat_case.daily_activity` AS activity
JOIN `steel-spark-430803-r3.Bellabeat_case.daily_steps` AS steps
  ON activity.Id = steps.Id
 AND activity.date = steps.`activity day`
LIMIT 100;

/* 1.3) intensities vs activity */
SELECT
  activity.Id,
  activity.date AS activity_date,
  activity.`sedentary minutes` AS activity_sedentary_minutes,
  intensities.`sedentary minutes` AS intensities_sedentary_minutes
FROM `steel-spark-430803-r3.Bellabeat_case.daily_activity` AS activity
JOIN `steel-spark-430803-r3.Bellabeat_case.daily_intensities` AS intensities
  ON activity.Id = intensities.Id
 AND activity.date = intensities.`activity day`
LIMIT 100;

/* Conclusion in the analysis: daily_calories, daily_intensities, daily_steps
   match the data in daily_activity for overlapping Id+date rows, so the
   analysis can proceed using daily_activity as the primary table.
*/

/* -----------------------------------------------------------
   2) USAGE FREQUENCY PER USER
   Purpose: How many days of data per user (proxy for device usage).
----------------------------------------------------------- */

-- 2.1) Count records by user
SELECT
  Id,
  COUNT(*) AS total_days
FROM `steel-spark-430803-r3.Bellabeat_case.daily_activity`
GROUP BY Id
ORDER BY total_days ASC;

-- 2.2) Classify users by number of days present (light/moderate/active)
SELECT
  Id,
  COUNT(*) AS total_days,
  CASE
    WHEN COUNT(*) BETWEEN 23 AND 31 THEN 'active_user'
    WHEN COUNT(*) BETWEEN 14 AND 22 THEN 'moderate_user'
    WHEN COUNT(*) BETWEEN 4  AND 13 THEN 'light_user'
    ELSE 'unclassified'
  END AS user_classification
FROM `steel-spark-430803-r3.Bellabeat_case.daily_activity`
GROUP BY Id
ORDER BY total_days DESC;

/* -----------------------------------------------------------
   3) DAILY MINUTES BY ACTIVITY CATEGORY (by day of week)
   Purpose: Average minutes spent in activity bins across days of week.
----------------------------------------------------------- */

SELECT
  `day of week`                                        AS day_of_week,
  ROUND(AVG(`very active minutes`),   2) AS avg_very_active_minutes,
  ROUND(AVG(`fairly active minutes`), 2) AS avg_fairly_active_minutes,
  ROUND(AVG(`lightly active minutes`),2) AS avg_lightly_active_minutes,
  ROUND(AVG(`sedentary minutes`),    2) AS avg_sedentary_minutes
FROM `steel-spark-430803-r3.Bellabeat_case.daily_activity`
GROUP BY day_of_week
ORDER BY avg_very_active_minutes DESC, avg_fairly_active_minutes DESC,
         avg_lightly_active_minutes DESC, avg_sedentary_minutes DESC;

/* -----------------------------------------------------------
   4) AVERAGE STEPS / DISTANCE / CALORIES BY DAY OF WEEK
   Purpose: Identify more/less active weekdays.
----------------------------------------------------------- */

SELECT
  `day of week`                         AS day_of_week,
  ROUND(AVG(` total steps`),   2) AS avg_steps,
  ROUND(AVG(`total distance`),  2) AS avg_distance,
  ROUND(AVG(calories),          2) AS avg_calories
FROM `steel-spark-430803-r3.Bellabeat_case.daily_activity`
GROUP BY day_of_week
ORDER BY avg_steps DESC;

/* -----------------------------------------------------------
   5) STEP-BASED ACTIVITY INDEX (Tudor-Locke thresholds)
   Source: https://pubmed.ncbi.nlm.nih.gov/14715035/
   Purpose: Classify each user by average daily steps.
   Buckets:
     < 5000          -> sedentary_lifestyle
     5000–7499       -> low_active
     7500–9999       -> somewhat_active
     10000–12499     -> active
     >= 12500        -> highly_active
----------------------------------------------------------- */

SELECT
  Id,
  ROUND(AVG(` total steps`), 2) AS avg_total_steps,
  CASE
    WHEN ROUND(AVG(` total steps`), 2) <  5000 THEN 'sedentary_lifestyle'
    WHEN ROUND(AVG(` total steps`), 2) BETWEEN  5000 AND  7499 THEN 'low_active'
    WHEN ROUND(AVG(` total steps`), 2) BETWEEN  7500 AND  9999 THEN 'somewhat_active'
    WHEN ROUND(AVG(` total steps`), 2) BETWEEN 10000 AND 12499 THEN 'active'
    WHEN ROUND(AVG(` total steps`), 2) >= 12500 THEN 'highly_active'
    ELSE 'unclassified'
  END AS total_steps_index
FROM `steel-spark-430803-r3.Bellabeat_case.daily_activity`
GROUP BY Id
ORDER BY avg_total_steps DESC;

/* -----------------------------------------------------------
   6) WHO PHYSICAL ACTIVITY GUIDELINES COMPLIANCE
   Source: https://www.who.int/news-room/fact-sheets/detail/physical-activity
   Purpose: Determine if users meet/exceed weekly 150–300 min moderate activity
            equivalent. Here we approximate via average daily minutes across
            activity bins (very/fairly/lightly active).
----------------------------------------------------------- */

-- 6.1) 3-class scheme: does not meet / meets (150–300) / exceeds (>=300)
SELECT
  Id,
  AVG(`very active minutes`) + AVG(`fairly active minutes`) + AVG(`lightly active minutes`) AS total_avg_active_minutes,
  CASE
    WHEN (AVG(`very active minutes`) + AVG(`fairly active minutes`) + AVG(`lightly active minutes`)) >= 300 THEN 'exceeds_WHO_recommendation'
    WHEN (AVG(`very active minutes`) + AVG(`fairly active minutes`) + AVG(`lightly active minutes`)) BETWEEN 150 AND 300 THEN 'meets_WHO_recommendation'
    ELSE 'does_not_meet_WHO_recommendation'
  END AS recommendation
FROM `steel-spark-430803-r3.Bellabeat_case.daily_activity`
GROUP BY Id
ORDER BY total_avg_active_minutes DESC;

-- 6.2) 2-class scheme: meets vs does_not_meet (threshold 150)
SELECT
  Id,
  AVG(`very active minutes`) + AVG(`fairly active minutes`) + AVG(`lightly active minutes`) AS total_avg_active_minutes,
  CASE
    WHEN (AVG(`very active minutes`) + AVG(`fairly active minutes`) + AVG(`lightly active minutes`)) >= 150 THEN 'meets_WHO_recommendation'
    ELSE 'does_not_meet_WHO_recommendation'
  END AS recommendation
FROM `steel-spark-430803-r3.Bellabeat_case.daily_activity`
GROUP BY Id
ORDER BY total_avg_active_minutes DESC;

/* -----------------------------------------------------------
   7) SLEEP VS ACTIVITY (JOIN sleep_day to daily_activity by Id)
   Purpose: Explore relationship between steps/calories and sleep.
----------------------------------------------------------- */

SELECT
  sd.Id,
  ROUND(AVG(da.` total steps`),  2) AS avg_steps,
  ROUND(AVG(da.calories),        2) AS avg_calories,
  ROUND(AVG(sd.TotalMinutesAsleep), 2) AS avg_minutes_asleep,
  ROUND(AVG(sd.TotalTimeInBed),     2) AS avg_time_in_bed,
  ROUND(AVG(sd.TotalTimeInBed - sd.TotalMinutesAsleep), 2) AS avg_time_awake
FROM `steel-spark-430803-r3.Bellabeat_case.sleep_day`        AS sd
JOIN `steel-spark-430803-r3.Bellabeat_case.daily_activity`   AS da
  ON sd.Id = da.Id
GROUP BY sd.Id
ORDER BY avg_minutes_asleep DESC;

/* -----------------------------------------------------------
   8) OPTIONAL: FILTER OUT ZERO-STEP DAYS (as quality check)
----------------------------------------------------------- */

SELECT *
FROM `steel-spark-430803-r3.Bellabeat_case.daily_activity`
WHERE ` total steps` > 0;

/* -----------------------------------------------------------
   9) OPTIONAL: CREATE DAY-OF-WEEK FEATURE (if missing)
   Note: If `day of week` already exists, skip. Otherwise derive from `date`.
----------------------------------------------------------- */

/* Example when `date` is a DATE or TIMESTAMP column:
SELECT
  Id,
  date,
  FORMAT_DATE('%A', DATE(date)) AS day_of_week
FROM `steel-spark-430803-r3.Bellabeat_case.daily_activity`
LIMIT 100;
*/
