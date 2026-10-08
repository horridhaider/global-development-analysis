-- 02 — Economic Development

-- Fields
-- gdp, gdp_pc, unemployment_rate


-- Analysis
-- A. Largest economies
-- - Top 10 GDP countries in 2024 (latest year in dataset)
SELECT
	dc.country_name,
	dc.region,
	ROUND(fe.gdp/1000000000000, 1) AS gdp_trillion
FROM
	dim_country dc
JOIN fact_economic fe
	ON dc.country_id = fe.country_id
WHERE	
	fe.year = 2024
	AND fe.gdp IS NOT NULL
ORDER BY
	gdp_trillion DESC
LIMIT 10;

-- - Bottom 10 Countries
SELECT
	dc.country_name,
	dc.region,
	ROUND(fe.gdp/1000000000, 1) AS gdp_billion
FROM
	dim_country dc
JOIN fact_economic fe
	ON dc.country_id = fe.country_id
WHERE	
	fe.year = 2024
	AND fe.gdp IS NOT NULL
ORDER BY
	gdp_billion
LIMIT 10;






-- B. GDP per capita
-- - Top countries
SELECT
	dc.country_name,
	dc.region,
	fe.gdp_pc
FROM
	dim_country dc
JOIN fact_economic fe
	ON dc.country_id = fe.country_id
WHERE
	fe.year = 2024
	AND fe.gdp_pc IS NOT NULL
ORDER BY
	gdp_pc DESC
LIMIT 10;

-- Bottom countries
SELECT
	dc.country_name,
	dc.region,
	fe.gdp_pc
FROM
	dim_country dc
JOIN fact_economic fe
	ON dc.country_id = fe.country_id
WHERE
	fe.year = 2024
	AND fe.gdp_pc IS NOT NULL
ORDER BY
	gdp_pc
LIMIT 10;






-- C. Economic growth
-- - GDP 2015 to 2024
WITH regions_gdp AS (
	SELECT
		fe.year,
		dc.region,
		SUM(fe.gdp)/1000000000000 AS total_gdp_trillion
	FROM
		fact_economic fe
	JOIN dim_country dc
		ON fe.country_id = dc.country_id
	GROUP BY
		fe.year,
		dc.region
)
SELECT 
	year, 
	region, 
	ROUND(total_gdp_trillion, 4) AS total_gdp_trillion, 
	
	ROUND((total_gdp_trillion - LAG(total_gdp_trillion) 
		OVER(PARTITION BY region ORDER BY year))*1000
		, 3) AS growth_in_billions,
		
	ROUND(((total_gdp_trillion - LAG(total_gdp_trillion) OVER(
		PARTITION BY region ORDER BY year)) 
		/ LAG(total_gdp_trillion) OVER (PARTITION BY region ORDER BY year)
		)*100, 3) AS growth_percentage
FROM
	regions_gdp
ORDER BY
	region,
	year;

-- - GDP per-capita growth
WITH regional_gdp_pc AS (
	SELECT
		fe.year,
		dc.region,
		SUM(fe.gdp_pc * fh.total_population) / SUM(fh.total_population) AS weighted_gdp_pc
	FROM
		fact_economic fe
	JOIN dim_country dc
		ON fe.country_id = dc.country_id
	JOIN fact_health fh
		ON fe.country_id = fh.country_id
		AND fe.year = fh.year
	GROUP BY
		dc.region,
		fe.year
)
SELECT
	year,
	region,
	ROUND(weighted_gdp_pc, 2) AS weighted_gdp_pc,
	
	ROUND(
	weighted_gdp_pc - LAG(weighted_gdp_pc) OVER(
		PARTITION BY region ORDER BY year)
		, 2) AS gdp_growth_usd,
	
	ROUND(((weighted_gdp_pc - LAG(weighted_gdp_pc) OVER(
		PARTITION BY region ORDER BY year))
		/ LAG(weighted_gdp_pc) OVER(PARTITION BY region ORDER BY year)
		)*100, 3) AS growth_percentage
FROM
	regional_gdp_pc
ORDER BY
	region,
	year;




-- D. Unemployment
-- - Highest/lowest countries in 2023
SELECT
	dc.country_name,
	dc.region,
	fe.unemployment_rate AS highest_unemployment_rates
FROM
	dim_country dc
JOIN fact_economic fe
	ON dc.country_id = fe.country_id
WHERE
	year = 2023
	AND unemployment_rate IS NOT NULL
ORDER BY
	unemployment_rate DESC
LIMIT 10;

SELECT
	dc.country_name,
	dc.region,
	fe.unemployment_rate AS lowest_unemployment_rates
FROM
	dim_country dc
JOIN fact_economic fe
	ON dc.country_id = fe.country_id
WHERE
	year = 2023
	AND unemployment_rate IS NOT NULL
ORDER BY
	unemployment_rate
LIMIT 10;
	
-- - Population-weighted Unemployment Rates in regions
SELECT
	fe.year,
	dc.region,
	ROUND(SUM(fe.unemployment_rate * fh.total_population) / SUM(fh.total_population), 3) AS weighted_unemployment_rate
FROM
	fact_economic fe
JOIN dim_country dc
	ON fe.country_id = dc.country_id
JOIN fact_health fh
	ON fe.country_id = fh.country_id
	AND fe.year = fh.year
GROUP BY
	fe.year,
	dc.region
ORDER BY
	dc.region,
	fe.year;

-- - Biggest improvement/worsening
WITH weighted_unemployment_regions AS (
	SELECT
		fe.year,
		dc.region,
		ROUND(SUM(fe.unemployment_rate * fh.total_population) / SUM(fh.total_population), 3) AS weighted_unemployment_rate
	FROM
		fact_economic fe
	JOIN dim_country dc
		ON fe.country_id = dc.country_id
	JOIN fact_health fh
		ON fe.country_id = fh.country_id
		AND fe.year = fh.year
	GROUP BY
		fe.year,
		dc.region
	ORDER BY
		dc.region,
		fe.year
),
weighted_difference AS (
	SELECT
		region,
		MAX(CASE 
			WHEN year = 2015 THEN weighted_unemployment_rate
		END) AS "2015_weighted_unemployment",
		
		MAX(CASE 
			WHEN year = 2023 THEN weighted_unemployment_rate
		END) AS "2023_weighted_unemployment"
	FROM
		weighted_unemployment_regions
	GROUP BY
		region
)
SELECT
	region,
	"2015_weighted_unemployment",
	"2023_weighted_unemployment",
	"2023_weighted_unemployment" - "2015_weighted_unemployment" AS unemployment_rate_change,
	CASE
		WHEN "2023_weighted_unemployment" - "2015_weighted_unemployment" < 0 THEN 'Improvement'
		WHEN "2023_weighted_unemployment" - "2015_weighted_unemployment" > 0 THEN 'Worsening'
		ELSE 'No change'
	END AS trend
FROM
	weighted_difference;

-- E. Economic ranking [to be fixed & improved]
SELECT
	dc.country_name,
	fe.gdp_pc,
	fh.life_expectancy,
	fs.literacy_rate,


	NTILE(4) OVER(
		PARTITION BY dc.country_name ORDER BY fe.gdp_pc DESC
	) AS gdp_quartile
	
FROM dim_country dc
JOIN fact_economic fe ON dc.country_id = fe.country_id
JOIN fact_health fh ON fe.country_id = fh.country_id
JOIN fact_social fs ON fh.country_id = fs.country_id
WHERE fe.year = 2022 AND fh.year = 2022 AND fs.year = 2022;
	
