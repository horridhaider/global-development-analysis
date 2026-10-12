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


-- - oldest → newest literacy rate change
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
	-- Calculate the difference between them
	(MAX(CASE WHEN rank_newest = 1 THEN literacy_rate END) - 
	 MAX(CASE WHEN rank_oldest = 1 THEN literacy_rate END)) AS literacy_change
FROM ranked_literacy 
WHERE rank_oldest = 1 OR rank_newest = 1
GROUP BY country_name, region
ORDER BY literacy_change DESC;		-- Countries with largest improvement


-- Human Rights [2024]
-- - Highest/lowest
WITH human_rights_table AS (
	SELECT
		dc.country_name,
		fs.human_rights_index
	FROM dim_country dc
	JOIN fact_social fs ON dc.country_id = fs.country_id
	WHERE fs.year = 2024 AND human_rights_index IS NOT NULL
)

SELECT 
    country_name, 
    human_rights_index, 
    'Above 0.90' AS category
FROM human_rights_table
WHERE human_rights_index > 0.90

UNION ALL

SELECT 
    country_name, 
    human_rights_index, 
    'Below 0.40' AS category
FROM human_rights_table
WHERE human_rights_index < 0.40
ORDER BY human_rights_index DESC;


-- - Regional comparison
SELECT
	dc.region,
	ROUND(AVG(fs.human_rights_index), 3) AS avg_human_rights
FROM dim_country dc
JOIN fact_social fs ON dc.country_id = fs.country_id
WHERE fs.year = 2024
GROUP BY dc.region
ORDER BY avg_human_rights DESC;


-- - 2015→2024 change
WITH ranked_human_rights AS (
	SELECT
		fs.year,
		dc.country_name,
		dc.region,
		fs.human_rights_index,
		-- Rank 1 is the oldest year
		ROW_NUMBER() OVER(PARTITION BY dc.country_name ORDER BY fs.year ASC) AS rank_oldest,
		-- Rank 1 is the newest year
		ROW_NUMBER() OVER(PARTITION BY dc.country_name ORDER BY fs.year DESC) AS rank_newest	
	FROM dim_country dc
	JOIN fact_social fs ON dc.country_id = fs.country_id
	WHERE fs.human_rights_index IS NOT NULL
)

SELECT
	country_name,
	region,
	-- Oldest values
	MAX(CASE WHEN rank_oldest = 1 THEN human_rights_index END) AS oldest_value,
	MAX(CASE WHEN rank_oldest = 1 THEN year END) AS oldest_year,
	-- Newest values
	MAX(CASE WHEN rank_newest = 1 THEN human_rights_index END) AS newest_value,
	MAX(CASE WHEN rank_newest = 1 THEN year END) AS newest_year,
	-- Calculate the difference between them
	(MAX(CASE WHEN rank_newest = 1 THEN human_rights_index END) - 
	 MAX(CASE WHEN rank_oldest = 1 THEN human_rights_index END)) AS human_rights_change
FROM ranked_human_rights 
WHERE rank_oldest = 1 OR rank_newest = 1
GROUP BY country_name, region
ORDER BY human_rights_change DESC;		-- Countries with largest improvement



-- question
-- Which countries experienced the strongest social improvement over the decade?
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
),

literacy_change AS (
	SELECT
		country_name,
		region,
		--Calculate the difference between them
		(MAX(CASE WHEN rank_newest = 1 THEN literacy_rate END) - 
		 MAX(CASE WHEN rank_oldest = 1 THEN literacy_rate END)) AS literacy_change
	FROM ranked_literacy 
	WHERE rank_oldest = 1 OR rank_newest = 1
	GROUP BY country_name, region
),

ranked_human_rights AS (
	SELECT
		fs.year,
		dc.country_name,
		dc.region,
		fs.human_rights_index,
		-- Rank 1 is the oldest year
		ROW_NUMBER() OVER(PARTITION BY dc.country_name ORDER BY fs.year ASC) AS rank_oldest,
		-- Rank 1 is the newest year
		ROW_NUMBER() OVER(PARTITION BY dc.country_name ORDER BY fs.year DESC) AS rank_newest	
	FROM dim_country dc
	JOIN fact_social fs ON dc.country_id = fs.country_id
	WHERE fs.human_rights_index IS NOT NULL
),

human_rights_change AS (
SELECT
	country_name,
	region,
	-- Calculate the difference between them
	(MAX(CASE WHEN rank_newest = 1 THEN human_rights_index END) - 
	 MAX(CASE WHEN rank_oldest = 1 THEN human_rights_index END)) AS human_rights_change
FROM ranked_human_rights 
WHERE rank_oldest = 1 OR rank_newest = 1
GROUP BY country_name, region
)


SELECT
	hc.country_name,
	hc.region,
	lc.literacy_change,
	hc.human_rights_change,
	CASE 
		WHEN lc.literacy_change > 0 AND hc.human_rights_change > 0 THEN 'Tier A'
		WHEN lc.literacy_change < 0 AND hc.human_rights_change > 0 THEN 'Tier B'
		WHEN lc.literacy_change > 0 AND hc.human_rights_change < 0 THEN 'Tier C'
		WHEN lc.literacy_change < 0 AND hc.human_rights_change < 0 THEN 'Tier D'
		ELSE 'Insufficient Data'
	END AS tier
FROM human_rights_change hc
LEFT JOIN literacy_change lc ON hc.country_name = lc.country_name
ORDER BY tier