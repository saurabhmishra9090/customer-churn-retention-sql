
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 2: Data Cleaning & Quality
-- STEP 1: Customer Data Quality Audit
--
-- PURPOSE:
-- Identify missing values, blank fields,
-- and invalid customer data formats.
--
-- IMPORTANT:
-- This is an audit query. It does not modify data.
-- =====================================================

-- SECTION 1: Calculate customer data quality metrics.
WITH customer_quality AS (

    SELECT
        COUNT(*) AS total_records,

        -- Check missing customer identifiers.
        COUNT(*) FILTER (
            WHERE customer_id IS NULL
        ) AS null_customer_ids,

        COUNT(*) FILTER (
            WHERE customer_unique_id IS NULL
        ) AS null_unique_customer_ids,

        -- Check missing location information.
        COUNT(*) FILTER (
            WHERE customer_zip_code_prefix IS NULL
        ) AS null_zip_codes,

        COUNT(*) FILTER (
            WHERE customer_city IS NULL
        ) AS null_cities,

        COUNT(*) FILTER (
            WHERE customer_state IS NULL
        ) AS null_states,

        -- Check blank text fields.
        COUNT(*) FILTER (
            WHERE TRIM(customer_city) = ''
        ) AS blank_cities,

        COUNT(*) FILTER (
            WHERE TRIM(customer_state) = ''
        ) AS blank_states,

        -- Check ZIP code format.
        COUNT(*) FILTER (
            WHERE customer_zip_code_prefix IS NOT NULL
              AND customer_zip_code_prefix !~ '^[0-9]{5}$'
        ) AS invalid_zip_codes,

        -- Check state code format.
        COUNT(*) FILTER (
            WHERE customer_state IS NOT NULL
              AND TRIM(customer_state) !~ '^[A-Z]{2}$'
        ) AS invalid_state_codes

    FROM olist.customers
)

-- SECTION 2: Display the audit results.
SELECT
    'Total Customer Records' AS quality_check,
    total_records::TEXT AS result,
    'Reference count of customer records' AS interpretation
FROM customer_quality

UNION ALL

SELECT
    'NULL Customer IDs',
    null_customer_ids::TEXT,
    'Expected: 0'
FROM customer_quality

UNION ALL

SELECT
    'NULL Unique Customer IDs',
    null_unique_customer_ids::TEXT,
    'Expected: 0'
FROM customer_quality

UNION ALL

SELECT
    'NULL ZIP Codes',
    null_zip_codes::TEXT,
    'Missing customer location information'
FROM customer_quality

UNION ALL

SELECT
    'NULL Cities',
    null_cities::TEXT,
    'Missing customer city information'
FROM customer_quality

UNION ALL

SELECT
    'NULL States',
    null_states::TEXT,
    'Missing customer state information'
FROM customer_quality

UNION ALL

SELECT
    'Blank Cities',
    blank_cities::TEXT,
    'Expected: 0'
FROM customer_quality

UNION ALL

SELECT
    'Blank States',
    blank_states::TEXT,
    'Expected: 0'
FROM customer_quality

UNION ALL

SELECT
    'Invalid ZIP Codes',
    invalid_zip_codes::TEXT,
    'Expected: 0 for five-digit numeric prefixes'
FROM customer_quality

UNION ALL

SELECT
    'Invalid State Codes',
    invalid_state_codes::TEXT,
    'Expected: 0 for two-letter uppercase codes'
FROM customer_quality;
