-- =========================================================================
-- 07 — Cross-Domain Analysis (Combined Summary Tables)
-- "How are different development indicators related?"
-- Note: GDP indicators use logarithmic transformation (LN) to account 
-- for non-linear scaling (diminishing marginal returns of wealth).
-- =========================================================================


-- -------------------------------------------------------------------------
-- 1. Economic → Health Correlations (Single Table)
-- -------------------------------------------------------------------------
SELECT
    -- Life Expectancy
    CORR(LN(fe.gdp_pc), fh.life_expectancy) AS gdppc_lifex_correlation,
    COUNT(fh.life_expectancy) AS sample_size_lifex,
    
    -- Under-15 Mortality
    CORR(LN(fe.gdp_pc), fh.mortality_rate_u15) AS gdppc_mortality_correlation,
    COUNT(fh.mortality_rate_u15) AS sample_size_mortality
FROM fact_economic fe
JOIN fact_health fh ON fe.country_id = fh.country_id AND fe.year = fh.year
WHERE fe.year = 2023;


-- -------------------------------------------------------------------------
-- 2. Economic → Social Correlations (Single Table)
-- -------------------------------------------------------------------------
SELECT
    -- Literacy Rate
    CORR(LN(fe.gdp_pc), fs.literacy_rate) AS gdppc_literacy_correlation,
    COUNT(fs.literacy_rate) AS sample_size_literacy,
    
    -- Human Rights Index
    CORR(LN(fe.gdp_pc), fs.human_rights_index) AS gdppc_humanrights_correlation,
    COUNT(fs.human_rights_index) AS sample_size_humanrights
FROM fact_economic fe
JOIN fact_social fs ON fe.country_id = fs.country_id AND fe.year = fs.year
WHERE fe.year = 2023;


-- -------------------------------------------------------------------------
-- 3. Economic → Poverty Correlations (Single Table)
-- -------------------------------------------------------------------------
SELECT
    -- Poverty Share
    CORR(LN(fe.gdp_pc), fp.poverty_share) AS gdppc_poverty_correlation,
    COUNT(fp.poverty_share) AS sample_size_poverty
FROM fact_economic fe
JOIN fact_poverty fp ON fe.country_id = fp.country_id AND fe.year = fp.year
WHERE fe.year = 2023;


-- -------------------------------------------------------------------------
-- 4. Social → Health Correlations (Single Table)
-- -------------------------------------------------------------------------
SELECT
    -- Literacy to Life Expectancy
    CORR(fs.literacy_rate, fh.life_expectancy) AS literacy_lifex_correlation,
    COUNT(fh.life_expectancy) AS sample_size_lifex,
    
    -- Literacy to Child Mortality
    CORR(fs.literacy_rate, fh.mortality_rate_u15) AS literacy_mortality_correlation,
    COUNT(fh.mortality_rate_u15) AS sample_size_mortality,
    
    -- Literacy to Homicide Rate
    CORR(fs.literacy_rate, fh.homicide_rate_p100k) AS literacy_homicide_correlation,
    COUNT(fh.homicide_rate_p100k) AS sample_size_homicide
FROM fact_social fs
JOIN fact_health fh ON fs.country_id = fh.country_id AND fs.year = fh.year
WHERE fs.year = 2023;