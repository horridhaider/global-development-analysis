-- 04 — Social Development
-- Fields
-- literacy_rate, human_rights_index

-- Analysis
-- Literacy
-- - Highest/lowest [data is scattered around the years, no single year in the dataset has all the countries. so the below approach is taken to get all the latest data for each available country]
WITH ranked_literacy AS (
	SELECT
		fs.year,
		dc.country_name,
		dc.region,
		fs.literacy_rate,
		ROW_NUMBER() OVER(PARTITION BY dc.country_name ORDER BY fs.year DESC) AS rank
	FROM dim_country dc
	JOIN fact_social fs ON dc.country_id = fs.country_id
	WHERE literacy_rate IS NOT NULL
),
literacy_countries AS (
	SELECT 
		year,
		country_name,
		region,
		literacy_rate AS latest_literacy
	FROM ranked_literacy
	WHERE rank = 1
),
categorized_literacy AS (
	SELECT
		country_name,
		year,
		region,
		CASE 
			 WHEN latest_literacy >= 99 THEN 'Above 99%'
			 WHEN latest_literacy <= 50 THEN 'Below 50%'
		END AS category
	FROM literacy_countries
)
SELECT 
	country_name,
	year AS latest_year,
	region,
	category
FROM categorized_literacy
WHERE category IS NOT NULL
ORDER BY category;


-- - Regional averages
WITH ranked_literacy AS (
	SELECT
		fs.year,
		dc.country_name,
		dc.region,
		fs.literacy_rate,
		ROW_NUMBER() OVER(PARTITION BY dc.country_name ORDER BY fs.year DESC) AS rank
	FROM dim_country dc
	JOIN fact_social fs ON dc.country_id = fs.country_id
	WHERE literacy_rate IS NOT NULL
)
SELECT
	region,
	ROUND(AVG(literacy_rate), 2) AS avg_literacy_rate
FROM ranked_literacy
WHERE rank = 1
GROUP BY region
ORDER BY avg_literacy_rate DESC;


-- - 2015→2024 change
WITH ranked_literacy AS (
	SELECT
		fs.year,
		dc.country_name,
		dc.region,
		fs.literacy_rate,
		-- Rank 1 is the oldest year
		ROW_NUMBER() OVER(PARTITION BY dc.country_name ORDER BY fs.year ASC) AS rank_oldest,
		-- Rank 1 is the newest year
		ROW_NUMBER() OVER(PARTITION BY dc.country_name ORDER BY fs.year DESC) AS rank_newest	
	FROM dim_country dc
	JOIN fact_social fs ON dc.country_id = fs.country_id
	WHERE fs.literacy_rate IS NOT NULL
)

SELECT
	country_name,
	region,
	-- Oldest values
	MAX(CASE WHEN rank_oldest = 1 THEN literacy_rate END) AS oldest_value,
	MAX(CASE WHEN rank_oldest = 1 THEN year END) AS oldest_year,
	-- Newest values
	MAX(CASE WHEN rank_newest = 1 THEN literacy_rate END) AS newest_value,
	MAX(CASE WHEN rank_newest = 1 THEN year END) AS newest_year,
	-- Optional: Calculate the difference between them
	(MAX(CASE WHEN rank_newest = 1 THEN literacy_rate END) - 
	 MAX(CASE WHEN rank_oldest = 1 THEN literacy_rate END)) AS literacy_change
FROM ranked_literacy 
WHERE rank_oldest = 1 OR rank_newest = 1
GROUP BY country_name, region
ORDER BY country_name;


-- - Countries with largest improvement


-- Human Rights
-- - Highest/lowest
-- - Regional comparison
-- - 2015→2024 change
-- question
-- Which countries experienced the strongest social improvement over the decade?