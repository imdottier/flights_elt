{{
    config(
        materialized='table',
        tags=['run_once']
    )
}}

WITH base AS (
    SELECT
        cast(date_format(d.full_date, 'yyyyMMdd') AS INT) AS date_key,
        to_date(d.full_date, 'yyyyMMdd') AS full_date,
        day(d.full_date) AS day_of_month,
        date_format(d.full_date, 'EEEE') AS day_name,
        weekday(d.full_date) + 1 AS day_of_week_iso,
        dayofyear(d.full_date) AS day_of_year,
        weekofyear(d.full_date) AS week_of_year,
        month(d.full_date) AS month_of_year,
        date_format(d.full_date, 'MMMM') AS month_name,
        quarter(d.full_date) AS quarter_of_year,
        year(d.full_date) AS year,
        CASE WHEN weekday(d.full_date) IN (5, 6) THEN TRUE ELSE FALSE END AS is_weekend

        -- PostgreSQL version:
        -- TO_CHAR(d.full_date, 'YYYYMMDD')::INT AS date_key,
        -- d.full_date,
        -- EXTRACT(DAY FROM d.full_date) AS day_of_month,
        -- TRIM(TO_CHAR(d.full_date, 'Day')) AS day_name,
        -- EXTRACT(ISODOW FROM d.full_date) AS day_of_week_iso,
        -- EXTRACT(DOY FROM d.full_date) AS day_of_year,
        -- EXTRACT(WEEK FROM d.full_date) AS week_of_year,
        -- EXTRACT(MONTH FROM d.full_date) AS month_of_year,
        -- TRIM(TO_CHAR(d.full_date, 'Month')) AS month_name,
        -- EXTRACT(QUARTER FROM d.full_date) AS quarter_of_year,
        -- EXTRACT(YEAR FROM d.full_date) AS year,
        -- CASE WHEN EXTRACT(ISODOW FROM d.full_date) IN (6, 7) THEN TRUE ELSE FALSE END AS is_weekend
    FROM (
        SELECT explode(sequence(to_date('2000-01-01'), to_date('2040-12-31'), INTERVAL 1 DAY)) AS full_date
        -- SELECT generate_series('2000-01-01'::DATE, '2040-12-31'::DATE, '1 day'::INTERVAL) AS full_date
    ) AS d
),

default_row AS (
    SELECT
        (-1) AS date_key,
        '1900-01-01'::DATE AS full_date,
        0 AS day_of_month,
        'Unknown' AS day_name,
        0 AS day_of_week_iso,
        0 AS day_of_year, 
        0 AS week_of_year,
        0 AS month_of_year,
        'Unknown' AS month_name,
        0 AS quarter_of_year,
        1900 AS year,
        FALSE AS is_weekend
)

SELECT * FROM base
UNION ALL
SELECT * FROM default_row