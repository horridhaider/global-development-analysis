COPY dim_country (country_name, region) FROM 'E:/coding/projects/SQL/project3/processed datasets/unique_countries.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');


INSERT INTO dim_year (year)
SELECT generate_series(2015, 2024);


COPY fact_economic FROM 'E:/coding/projects/SQL/project3/processed datasets/economic_indicators.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

COPY fact_health FROM 'E:/coding/projects/SQL/project3/processed datasets/health_indicators.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

COPY fact_social FROM 'E:/coding/projects/SQL/project3/processed datasets/social_indicators.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

COPY fact_poverty FROM 'E:/coding/projects/SQL/project3/processed datasets/poverty_indicators.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
