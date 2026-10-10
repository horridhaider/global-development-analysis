-- 03 — Health & Safety
-- Fields
-- life_expectancy, mortality_rate_u15, homicide_rate_p100k, total_population

-- Analysis

-- A. Life expectancy [2023]

-- - Highest/lowest countries
SELECT	-- top 10 high life expectancy countries
	dc.country_name,
	dc.region,
	fh.life_expectancy AS high_life_expectancy
FROM dim_country dc
JOIN fact_health fh ON dc.country_id = fh.country_id
WHERE fh.year = 2023 
ORDER BY high_life_expectancy DESC
LIMIT 10;

SELECT    -- Bottom 10 low life expectancy countries
	dc.country_name,
	dc.region,
	fh.life_expectancy AS low_life_expectancy
FROM dim_country dc
JOIN fact_health fh ON dc.country_id = fh.country_id
WHERE fh.year = 2023 
ORDER BY low_life_expectancy
LIMIT 10;


-- - 2015→2023 improvement
WITH life_expectancy_pivot AS (
	SELECT
		dc.country_name,
		ROUND(MAX(CASE WHEN fh.year = 2015 THEN fh.life_expectancy END), 2) AS life_expectancy_2015,
		ROUND(MAX(CASE WHEN fh.year = 2023 THEN fh.life_expectancy END), 2) AS life_expectancy_2023
	FROM dim_country dc
	JOIN fact_health fh ON dc.country_id = fh.country_id
	GROUP BY dc.country_name
)

SELECT
	*,
	ROUND(((life_expectancy_2023 - life_expectancy_2015) / life_expectancy_2015)*100, 3) AS percentage_change,
	CASE 
		 WHEN ((life_expectancy_2023 - life_expectancy_2015) / life_expectancy_2015)*100 > 0 THEN 'Improving'
	     WHEN ((life_expectancy_2023 - life_expectancy_2015) / life_expectancy_2015)*100 < 0 THEN 'Worsening' 
	END AS change_type
FROM life_expectancy_pivot
ORDER BY percentage_change;


-- - Regional trends
WITH region_averages AS (
	SELECT
		fh.year,
		dc.region,
		AVG(fh.life_expectancy) AS avg_life_expectancy
	FROM dim_Country dc
	JOIN fact_health fh ON dc.country_id = fh.country_id
	GROUP BY fh.year, dc.region
	ORDER BY year, region
)
SELECT
	region,
	ROUND(MAX(CASE WHEN year = 2015 THEN avg_life_expectancy END),2) AS life_exp_2015,
	ROUND(MAX(CASE WHEN year = 2016 THEN avg_life_expectancy END),2) AS life_exp_2016,
	ROUND(MAX(CASE WHEN year = 2017 THEN avg_life_expectancy END),2) AS life_exp_2017,
	ROUND(MAX(CASE WHEN year = 2018 THEN avg_life_expectancy END),2) AS life_exp_2018,
	ROUND(MAX(CASE WHEN year = 2019 THEN avg_life_expectancy END),2) AS life_exp_2019,
	ROUND(MAX(CASE WHEN year = 2020 THEN avg_life_expectancy END),2) AS life_exp_2020,
	ROUND(MAX(CASE WHEN year = 2021 THEN avg_life_expectancy END),2) AS life_exp_2021,
	ROUND(MAX(CASE WHEN year = 2022 THEN avg_life_expectancy END),2) AS life_exp_2022,
	ROUND(MAX(CASE WHEN year = 2023 THEN avg_life_expectancy END),2) AS life_exp_2023
FROM region_averages
GROUP BY region;



-- B. Child mortality
-- - Highest/lowest
SELECT	-- 10 lowest Child mortality countries
	dc.country_name,
	dc.region,
	fh.mortality_rate_u15 AS mortality_rate_u15
FROM dim_country dc
JOIN fact_health fh ON dc.country_id = fh.country_id
WHERE fh.year = 2023 
ORDER BY mortality_rate_u15
LIMIT 10;

SELECT    -- 10 highest Child mortality countries
	dc.country_name,
	dc.region,
	fh.mortality_rate_u15 AS mortality_rate_u15
FROM dim_country dc
JOIN fact_health fh ON dc.country_id = fh.country_id
WHERE fh.year = 2023 AND fh.mortality_rate_u15 IS NOT NULL
ORDER BY mortality_rate_u15 DESC
LIMIT 10;


-- - Biggest reductions
WITH mortality_years AS (
SELECT	
	dc.country_name AS top_reduction_countries,
	dc.region,
	MAX(CASE WHEN year = 2015 THEN fh.mortality_rate_u15 END) AS mortality_rate_2015,
	MAX(CASE WHEN year = 2023 THEN fh.mortality_rate_u15 END) AS mortality_rate_2023
FROM dim_country dc
JOIN fact_health fh ON dc.country_id = fh.country_id
GROUP BY dc.country_name, dc.region
)

SELECT
	*,
	ROUND(((mortality_rate_2023 - mortality_rate_2015) / mortality_rate_2015)*100, 3) AS child_mortality_perc_change
FROM mortality_years
ORDER BY child_mortality_perc_change
LIMIT 10;


-- - Regional improvement
WITH mortality_years_region AS (
SELECT	
	dc.region,
	ROUND(AVG(CASE WHEN year = 2015 AND fh.mortality_rate_u15 > 0 THEN fh.mortality_rate_u15 END),3) AS avg_mortality_rate_2015,
	ROUND(AVG(CASE WHEN year = 2023 AND fh.mortality_rate_u15 > 0 THEN fh.mortality_rate_u15 END),3) AS avg_mortality_rate_2023
FROM dim_country dc
JOIN fact_health fh ON dc.country_id = fh.country_id
GROUP BY dc.region
)

SELECT
	*,
	ROUND(((avg_mortality_rate_2023 - avg_mortality_rate_2015) / avg_mortality_rate_2015)*100, 3) AS child_mortality_perc_change
FROM 
	mortality_years_region
ORDER BY child_mortality_perc_change;


-- C. Homicide Rate [2023] [available countries only]
-- - Highest rate
SELECT
	dc.country_name,
	fh.homicide_rate_p100k
FROM dim_country dc
JOIN fact_health fh ON dc.country_id = fh.country_id
WHERE fh.year = 2023 AND fh.homicide_rate_p100k IS NOT NULL
ORDER BY fh.homicide_rate_p100k DESC
LIMIT 10;

-- - Lowest rate
SELECT
	dc.country_name,
	fh.homicide_rate_p100k
FROM dim_country dc
JOIN fact_health fh ON dc.country_id = fh.country_id
WHERE fh.year = 2023 AND fh.homicide_rate_p100k IS NOT NULL
ORDER BY fh.homicide_rate_p100k 
LIMIT 10;


-- - Regional comparison [2023]
SELECT
	dc.region,
	ROUND(AVG(fh.homicide_rate_p100k), 3) AS avg_homicide_rate,
	COUNT(fh.homicide_rate_p100k) AS countries_included,
	COUNT(dc.country_id) AS total_countries
FROM dim_country dc
JOIN fact_health fh ON dc.country_id = fh.country_id
WHERE fh.year = 2023
GROUP BY dc.region
ORDER BY avg_homicide_rate;


-- - Countries with major increases/decreases
WITH homicide_years AS (
	SELECT
		dc.country_name,
		ROUND(MAX(CASE WHEN fh.year = 2015 THEN fh.homicide_rate_p100k END), 3) AS homicide_rate_2015,
		ROUND(MAX(CASE WHEN fh.year = 2023 THEN fh.homicide_rate_p100k END), 3) AS homicide_rate_2023
	FROM dim_country dc
	JOIN fact_health fh ON dc.country_id = fh.country_id
	GROUP BY dc.country_name
),
calculated_changes AS (
	SELECT
		*,
		ROUND(((homicide_rate_2023 - homicide_rate_2015) / homicide_rate_2015)*100, 3) AS percentage_change
	FROM homicide_years
	WHERE homicide_rate_2015 IS NOT NULL 	AND  	homicide_rate_2023 IS NOT NULL
)

(SELECT *, 'Highest Increase (Top 10)' AS report_section FROM calculated_changes ORDER BY percentage_change DESC LIMIT 10)
UNION ALL
(SELECT *, 'Biggest Decrease (Bottom 10)' AS report_section FROM calculated_changes ORDER BY percentage_change ASC LIMIT 10)
ORDER BY report_section DESC, percentage_change DESC;




-- D. Population
-- - Largest populations [10]
SELECT
	dc.country_name,
	fh.total_population
FROM dim_country dc
JOIN fact_health fh ON dc.country_id = fh.country_id
WHERE fh.year = 2023
ORDER BY total_population DESC
LIMIT 10;

-- - Population growth
WITH population_years AS (
	SELECT
		dc.country_name,
		ROUND(MAX(CASE WHEN fh.year = 2015 THEN fh.total_population END)) AS population_2015,
		ROUND(MAX(CASE WHEN fh.year = 2023 THEN fh.total_population END)) AS population_2023
	FROM dim_country dc
	JOIN fact_health fh ON dc.country_id = fh.country_id
	GROUP BY dc.country_name
),
calculated_changes AS (
	SELECT
		*,
		ROUND(((CAST(population_2023 AS NUMERIC) - CAST(population_2015 AS NUMERIC)) / NULLIF(CAST(population_2015 AS NUMERIC), 0)) * 100, 3) AS percentage_change
	FROM population_years
	ORDER BY percentage_change DESC
)

(SELECT *, 'Highest Increase (Top 10)' AS report_section FROM calculated_changes ORDER BY percentage_change DESC LIMIT 10)
UNION ALL
(SELECT *, 'Biggest Decrease (Bottom 10)' AS report_section FROM calculated_changes ORDER BY percentage_change ASC LIMIT 10)
ORDER BY report_section DESC, percentage_change DESC;



-- - Regional population changes
WITH population_region AS (
	SELECT
		dc.region,
		SUM(CASE WHEN fh.year = 2015 THEN fh.total_population END) AS population_2015,
		SUM(CASE WHEN fh.year = 2023 THEN fh.total_population END) AS population_2023
	FROM dim_country dc
	JOIN fact_health fh ON dc.country_id = fh.country_id
	GROUP BY dc.region
)
SELECT
	*,
	ROUND(((population_2023 - population_2015) / population_2015)*100, 3) AS percentage_change
FROM population_region
ORDER BY percentage_change DESC;



-- Final Insight Table (following KPIs)
-- Mortality reduction %
-- Homicide change %
-- Life expectancy increase
-- Population growth %