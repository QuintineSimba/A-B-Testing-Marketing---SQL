CREATE TABLE marketing_ab (
    row_index INT,
    user_id INT,
    test_group VARCHAR(50),
    converted VARCHAR(10),
    total_ads INT,
    most_ads_day VARCHAR(50),
    most_ads_hour INT,
    PRIMARY KEY (user_id)
);


-- 1. Enable local file loading on your server
SET GLOBAL local_infile = 1;

-- 2. Run the fast import
LOAD DATA LOCAL INFILE 'C:/Users/quint/Downloads/marketing_AB.csv'
INTO TABLE marketing_ab
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;


-- STEP 1 — Load the data into your database and explore it--
-- How many rows do we have?
SELECT COUNT(*) AS total_rows
FROM marketing_ab;

-- How are users split between the two groups?
SELECT 
    test_group,
    COUNT(*) AS users,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM marketing_ab
GROUP BY test_group;

-- STEP 2 — Calculate conversion rates
-- The core question: do people who see ads convert at a higher rate?

SELECT 
    test_group,
    COUNT(*) AS total_users,
    SUM(CASE WHEN converted IN ('true', 'TRUE', '1') THEN 1 ELSE 0 END) AS converted_users,
    ROUND(
        SUM(CASE WHEN converted IN ('true', 'TRUE', '1') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS conversion_rate_pct
FROM marketing_ab
GROUP BY test_group;

-- STEP 3 — Look at ad exposure
-- Not all users in the ad group saw the same number of ads. Does seeing more ads make you more likely to convert?

SELECT 
    test_group,
    ROUND(AVG(total_ads), 1) AS avg_ads_seen,
    MIN(total_ads) AS min_ads,
    MAX(total_ads) AS max_ads
FROM marketing_ab
GROUP BY test_group;

-- Both groups average 24.8 ads seen. Let's look at conversion rate by ad volume:

SELECT 
    CASE 
        WHEN total_ads BETWEEN 1 AND 10 THEN '1-10 ads'
        WHEN total_ads BETWEEN 11 AND 50 THEN '11-50 ads'
        WHEN total_ads BETWEEN 51 AND 100 THEN '51-100 ads'
        ELSE '100+ ads'
    END AS ads_bucket,
    COUNT(*) AS users,
    ROUND(
        SUM(CASE WHEN converted IN ('true', 'TRUE', '1') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS conversion_rate_pct
FROM marketing_ab
WHERE test_group = 'ad'
GROUP BY ads_bucket
ORDER BY ads_bucket;

-- STEP 4 — Find the best day and hour to show ads

-- Which day of the week drives the most conversions?
SELECT 
    most_ads_day,
    COUNT(*) AS users,
    SUM(CASE WHEN converted IN ('true', 'TRUE', '1') THEN 1 ELSE 0 END) AS conversions,
    ROUND(
        SUM(CASE WHEN converted IN ('true', 'TRUE', '1') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS conversion_rate_pct
FROM marketing_ab
WHERE test_group = 'ad'
GROUP BY most_ads_day
ORDER BY conversion_rate_pct DESC;

-- Which hour of the day drives the most conversions?
SELECT 
    most_ads_hour,
    COUNT(*) AS users,
    ROUND(
        SUM(CASE WHEN converted IN ('true', 'TRUE', '1') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS conversion_rate_pct
FROM marketing_ab
WHERE test_group = 'ad'
GROUP BY most_ads_hour
ORDER BY conversion_rate_pct DESC
LIMIT 5;

-- STEP 6 — Findings Summary

SELECT 
    test_group,
    COUNT(*) AS total_users,
    SUM(CASE WHEN converted IN ('true', 'TRUE', '1') THEN 1 ELSE 0 END) AS conversions,
    ROUND(
        SUM(CASE WHEN converted IN ('true', 'TRUE', '1') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS conversion_rate_pct,
    ROUND(AVG(total_ads), 1) AS avg_ads_seen
FROM marketing_ab
GROUP BY test_group;

-- What would you tell a stakeholder? 

-- 1. The ad campaign drove a 43% relative lift in conversion rate compared to the control group (2.55% vs 1.79% across 588,000 users)
-- 2. Conversion rate increases steadily with ad frequency, reaching 17% for users who saw 100 or more ads
-- 3. Monday and mid-to-late afternoon (14:00-16:00) and early evening (20:00-21:00) are the highest-converting windows

-- These are the recommendations the business can act on.



















