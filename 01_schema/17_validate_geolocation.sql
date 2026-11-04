
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- TABLE: geolocation
-- FILE: 17_validate_geolocation.sql
-- PURPOSE: Geographical data quality and duplicate analysis
-- =====================================================


-- 1. Overall validation

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT geolocation_zip_code_prefix)
        AS unique_zip_prefixes,
    COUNT(*) FILTER (
        WHERE geolocation_zip_code_prefix IS NULL
    ) AS null_zip_prefixes,
    COUNT(*) FILTER (
        WHERE geolocation_lat IS NULL
    ) AS null_latitudes,
    COUNT(*) FILTER (
        WHERE geolocation_lng IS NULL
    ) AS null_longitudes,
    COUNT(*) FILTER (
        WHERE geolocation_city IS NULL
    ) AS null_cities,
    COUNT(*) FILTER (
        WHERE geolocation_state IS NULL
    ) AS null_states
FROM olist.geolocation;


-- 2. Coordinate range validation

SELECT
    COUNT(*) FILTER (
        WHERE geolocation_lat NOT BETWEEN -90 AND 90
    ) AS invalid_latitudes,
    COUNT(*) FILTER (
        WHERE geolocation_lng NOT BETWEEN -180 AND 180
    ) AS invalid_longitudes
FROM olist.geolocation;


-- 3. Duplicate ZIP prefix analysis

SELECT
    geolocation_zip_code_prefix,
    COUNT(*) AS coordinate_records,
    COUNT(DISTINCT geolocation_city) AS unique_cities,
    COUNT(DISTINCT geolocation_state) AS unique_states
FROM olist.geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1
ORDER BY coordinate_records DESC
LIMIT 10;


-- 4. Geographic state distribution

SELECT
    geolocation_state,
    COUNT(*) AS total_records,
    COUNT(DISTINCT geolocation_zip_code_prefix)
        AS unique_zip_prefixes
FROM olist.geolocation
GROUP BY geolocation_state
ORDER BY total_records DESC;
