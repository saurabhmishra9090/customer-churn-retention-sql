
-- Project: Customer Churn & Retention Intelligence
-- Purpose: Verify database and create schema if missing

-- 1. Verify current database
SELECT current_database();

-- 2. Ensure Olist schema exists
CREATE SCHEMA IF NOT EXISTS olist;

-- 3. Verify schema
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'olist';
