CREATE TABLE dim_country (
    country_id SERIAL PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL UNIQUE,
    region VARCHAR(50) NOT NULL
);


CREATE TABLE dim_year (
    year SMALLINT PRIMARY KEY
);


CREATE TABLE fact_economic (
    country_id INT REFERENCES dim_country(country_id),
    year SMALLINT REFERENCES dim_year(year),

    gdp NUMERIC,
    gdp_pc NUMERIC,
    unemployment_rate NUMERIC,

    PRIMARY KEY (country_id, year)
);


CREATE TABLE fact_health (
    country_id INT REFERENCES dim_country(country_id),
    year SMALLINT REFERENCES dim_year(year),

    total_population BIGINT,
    life_expectancy NUMERIC,
    mortality_rate_u15 NUMERIC,
    homicide_rate_p100k NUMERIC,

    PRIMARY KEY (country_id, year)
);


CREATE TABLE fact_social (
    country_id INT REFERENCES dim_country(country_id),
    year SMALLINT REFERENCES dim_year(year),

    literacy_rate NUMERIC,
    human_rights_index NUMERIC,

    PRIMARY KEY (country_id, year)
);


CREATE TABLE fact_poverty (
    country_id INT REFERENCES dim_country(country_id),
    year SMALLINT REFERENCES dim_year(year),

    poverty_share NUMERIC,
    poverty_number BIGINT,

    PRIMARY KEY (country_id, year)
);