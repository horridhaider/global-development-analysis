-- 05 — Poverty
-- Fields:		poverty_share, poverty_number, total_population

-- Analysis
-- A. Poverty scale
-- - Countries with largest poor populations
WITH rank_poverty AS (
	SELECT
		country_id,
		year,
		poverty_share,
		poverty_number,
		ROW_NUMBER() OVER(PARTITION BY country_id ORDER BY year DESC) AS rank
	FROM fact_poverty
)

SELECT
	dc.country_name,
	dc.region,
	rp.poverty_number
FROM dim_country dc
JOIN rank_poverty rp ON dc.country_id = rp.country_id
WHERE rank = 1		-- this only gives the rows with data belonging to the latest year 
ORDER BY poverty_number DESC		-- largest poor population 
LIMIT 10;							-- [top 10]


-- - Countries with highest poverty shares
WITH rank_poverty AS (
	SELECT
		country_id,
		year,
		poverty_share,
		ROW_NUMBER() OVER(PARTITION BY country_id ORDER BY year DESC) AS rank
	FROM fact_poverty
)

SELECT
	dc.country_name,
	dc.region,
	rp.poverty_share
FROM dim_country dc
JOIN rank_poverty rp ON dc.country_id = rp.country_id
WHERE rank = 1					-- latest year 
ORDER BY poverty_share DESC		-- highest poverty shares 
LIMIT 10;						-- [top 10]




-- B. Poverty reduction
-- - 2015 → 2023
SELECT
	dc.country_name,
	MAX(CASE WHEN year = 2023 THEN fp.poverty_share END)
		- MAX(CASE WHEN year = 2015 THEN fp.poverty_share END) AS poverty_share_change
FROM dim_country dc
JOIN fact_poverty fp ON dc.country_id = fp.country_id
GROUP BY dc.country_name
ORDER BY poverty_share_change;	-- negative values mean decrease in poverty share




-- C. Regional poverty [2022]
-- - Poverty population
SELECT
	dc.region,
	SUM(fp.poverty_number) AS poverty_population
FROM dim_country dc
JOIN fact_Poverty fp ON dc.country_id = fp.country_id
WHERE fp.year = 2022
GROUP BY dc.region
ORDER BY poverty_population DESC;


-- - Weighted poverty share [2023]
SELECT
	dc.region,
	SUM(fp.poverty_share * fh.total_population) / SUM(fh.total_population) AS weighted_poverty_share
FROM dim_country dc
JOIN fact_poverty fp ON dc.country_id = fp.country_id
JOIN fact_health fh ON fp.country_id = fh.country_id
WHERE fp.year = 2023
GROUP BY dc.region
ORDER BY weighted_poverty_share DESC;



-- D. Poverty vs population
-- - Large countries with relatively low poverty
WITH population_poverty AS (
	SELECT
		dc.country_name,
		fh.total_population,
		fp.poverty_number
	FROM dim_country dc
	JOIN fact_poverty fp ON dc.country_id = fp.country_id
	JOIN fact_health fh ON fp.country_id = fh.country_id AND fp.year = fh.year
	WHERE fp.year = 2022
)

SELECT
	*,
	ROUND((poverty_number * 1.0 / total_population)*100, 2) AS poverty_percentage
FROM population_poverty
WHERE poverty_number > 0 	-- because some outliers might be present that have 0 value (unrealistically)
ORDER BY total_population DESC, poverty_percentage ASC;


-- - Small countries with high poverty
WITH population_poverty AS (
	SELECT
		dc.country_name,
		fh.total_population,
		fp.poverty_number
	FROM dim_country dc
	JOIN fact_poverty fp ON dc.country_id = fp.country_id
	JOIN fact_health fh ON fp.country_id = fh.country_id AND fp.year = fh.year
	WHERE fp.year = 2022
)

SELECT
	*,
	ROUND((poverty_number * 1.0 / total_population)*100, 2) AS poverty_percentage
FROM population_poverty
WHERE poverty_number > 0 	-- for outliers
ORDER BY poverty_percentage DESC, total_population ASC;

