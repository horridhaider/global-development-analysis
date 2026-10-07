-- Global KPIs


-- Total World GDP
SELECT 
	year,
	ROUND(SUM(gdp)/1000000000000, 1) AS global_gdp_trillion
FROM 
	fact_economic
GROUP BY 
	year
ORDER BY 
	year;


-- Global population (in billions)
SELECT 
	year,
	ROUND(SUM(total_population)/1000000000, 2) AS global_population_billions
FROM 
	fact_health
GROUP BY 
	year
ORDER BY 
	year;


-- Weighted/average GDP per capita
SELECT
    fh.year,
    ROUND(SUM(fh.total_population * fe.gdp_pc) / SUM(fh.total_population), 1) AS global_weighted_gdp_pc
FROM 
	fact_health fh
JOIN fact_economic fe 
	ON fh.country_id = fe.country_id 
	AND fh.year = fe.year
GROUP BY 
	fh.year
ORDER BY 
	fh.year;


-- Average Weighted Unemployment Rate Across regions in different years
SELECT
    fe.year,
    dc.region,
    ROUND(
        SUM(fe.unemployment_rate * fh.total_population) / SUM(fh.total_population), 
        2
    ) AS regional_weighted_unemployment_rate
FROM fact_economic fe
JOIN dim_country dc
    ON fe.country_id = dc.country_id
JOIN fact_health fh
    ON fe.country_id = fh.country_id AND fe.year = fh.year
WHERE fe.unemployment_rate IS NOT NULL	
GROUP BY
    fe.year,
    dc.region
ORDER BY
    dc.region,
    fe.year;


-- Avg Life Expectancy (by both year and region)
SELECT
	fh.year,
	dc.region,
	ROUND(AVG(fh.life_expectancy), 2) AS avg_life_expectancy
FROM
	dim_country dc
JOIN fact_health fh
	ON dc.country_id = fh.country_id
GROUP BY
	dc.region, fh.year
ORDER BY
	dc.region, fh.year;


-- Average under-15 mortality (year & region)
WITH regional_averages AS (	
	SELECT
		fh.year,
		dc.region,
		ROUND(AVG(fh.mortality_rate_u15), 2) AS mortality_rate_under_15
	FROM
		dim_country dc
	JOIN fact_health fh
		ON dc.country_id = fh.country_id
	GROUP BY
		dc.region, fh.year
	)
SELECT
	year,
	region,
	mortality_rate_under_15 AS mortality_rate_under_15,
	mortality_rate_under_15 - LAG(mortality_rate_under_15) OVER(PARTITION BY region ORDER BY year) AS yearly_change
FROM
	regional_averages;

 
-- Average homicide rate (year & region)
SELECT
	fh.year,
	dc.region,
	ROUND(AVG(fh.homicide_rate_p100k), 2) AS homicide_rate_per_100k
FROM
	dim_country dc
JOIN fact_health fh
	ON dc.country_id = fh.country_id
GROUP BY
	dc.region, fh.year
ORDER BY
	dc.region, fh.year;


-- Average literacy rate
SELECT
    fs.year,
    dc.region,
    ROUND(
        SUM(fs.literacy_rate * fh.total_population) / SUM(fh.total_population), 
        2
    ) AS regional_weighted_literacy_rate
FROM fact_social fs
JOIN dim_country dc
    ON fs.country_id = dc.country_id
JOIN fact_health fh
    ON fs.country_id = fh.country_id AND fs.year = fh.year
WHERE fs.literacy_rate IS NOT NULL			-- this one is so important because if some countries do not have literacy rate mentioned but its population is there it would mess up the output
GROUP BY
    fs.year,
    dc.region
ORDER BY
    dc.region,
    fs.year;

-- Average Human Rights Index
SELECT 
	fs.year,
	dc.region,
	ROUND(AVG(fs.human_rights_index), 4) AS avg_human_rights_index
FROM
	fact_social fs
JOIN dim_country dc
	ON fs.country_id = dc.country_id
GROUP BY
	dc.region,
	fs.year
ORDER BY
	dc.region,
	fs.year;



-- Global poverty population
SELECT
	year,
	ROUND(SUM(poverty_number)/1000000, 1) AS poverty_population_million
FROM
	fact_poverty
GROUP BY
	year
ORDER BY
	year;


-- Average poverty share
SELECT
	fp.year,
	dc.region AS region_reported_countries_only,
	CONCAT(ROUND(SUM(fp.poverty_share * fh.total_population) / SUM(fh.total_population), 2), '%') AS weighted_poverty_share
FROM
	dim_country dc
JOIN fact_poverty fp
	ON dc.country_id = fp.country_id
JOIN fact_health fh
	ON fp.country_id = fh.country_id AND fp.year = fh.year
WHERE
	fp.poverty_share IS NOT NULL
GROUP BY
	fp.year,
	dc.region
ORDER BY
	fp.year,
	dc.region;