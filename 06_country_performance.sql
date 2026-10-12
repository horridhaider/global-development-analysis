-- 06 — Country Performance
CREATE VIEW fact_global_metrics AS (
	SELECT
		dc.country_name, dc.region,
		fe.gdp, fe.gdp_pc, fe.unemployment_rate,
		fh.total_population, fh.life_expectancy, fh.mortality_rate_u15, fh.homicide_rate_p100k,
		fs.literacy_rate, fs.human_rights_index,
		fp.poverty_share, fp.poverty_number
	FROM dim_country dc
	JOIN fact_economic fe ON dc.country_id = fe.country_id
	JOIN fact_health fh ON fe.country_id = fh.country_id AND fe.year = fh.year
	JOIN fact_social fs ON fh.country_id = fs.country_id AND fh.year = fs.year
	LEFT JOIN fact_poverty fp ON fs.country_id = fp.country_id AND fs.year = fp.year
	WHERE fe.year = 2022
);

SELECT * FROM fact_global_metrics;


-- "Which countries performed best across multiple dimensions?"
-- Categories:

-- Economic leaders
SELECT
	* 
FROM fact_global_metrics
WHERE gdp IS NOT NULL AND gdp_pc IS NOT NULL AND unemployment_rate IS NOT NULL
ORDER BY gdp DESC, gdp_pc DESC, unemployment_rate ASC
LIMIT 20;

-- Health leaders
SELECT
	*
FROM fact_global_metrics
WHERE total_population IS NOT NULL AND life_expectancy IS NOT NULL AND mortality_rate_u15 IS NOT NULL AND homicide_rate_p100k IS NOT NULL
ORDER BY life_expectancy DESC, total_population DESC, mortality_rate_u15 ASC, homicide_rate_p100k ASC
LIMIT 20;

-- Social leaders
SELECT
	*
FROM fact_global_metrics
WHERE literacy_rate IS NOT NULL AND human_rights_index IS NOT NULL 
ORDER BY human_rights_index DESC, literacy_rate DESC
LIMIT 20;

-- Poverty reduction leaders
SELECT
	*
FROM fact_global_metrics
WHERE poverty_share IS NOT NULL AND poverty_number IS NOT NULL 
ORDER BY poverty_share ASC, poverty_number ASC
LIMIT 20;

-- Overall development leaders
WITH metric_ranks AS (
	SELECT 
		country_name,
		-- Rank each metric (1 = Best)
		DENSE_RANK() OVER (ORDER BY gdp DESC, gdp_pc DESC, unemployment_rate ASC) AS rank_econ,
		DENSE_RANK() OVER (ORDER BY life_expectancy DESC, mortality_rate_u15 ASC, homicide_rate_p100k ASC) AS rank_health,
		DENSE_RANK() OVER (ORDER BY human_rights_index DESC, literacy_rate DESC) AS rank_social,
		DENSE_RANK() OVER (ORDER BY poverty_share ASC, poverty_number ASC) AS rank_poverty
	FROM fact_global_metrics
	WHERE gdp IS NOT NULL 
	  AND life_expectancy IS NOT NULL 
	  AND human_rights_index IS NOT NULL 
	  AND poverty_share IS NOT NULL
)
SELECT 
	country_name,
	rank_econ,
	rank_health,
	rank_social,
	rank_poverty,
	ROUND((rank_econ + rank_health + rank_social + rank_poverty) / 4.0, 2) AS avg_rank
FROM metric_ranks
ORDER BY avg_rank ASC
LIMIT 20;