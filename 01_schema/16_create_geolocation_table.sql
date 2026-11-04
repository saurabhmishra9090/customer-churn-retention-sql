
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- TABLE: geolocation
-- PURPOSE: Create geographical reference table
-- =====================================================

CREATE TABLE IF NOT EXISTS olist.geolocation (
    geolocation_zip_code_prefix VARCHAR(5),
    geolocation_lat NUMERIC(10,7),
    geolocation_lng NUMERIC(10,7),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);
