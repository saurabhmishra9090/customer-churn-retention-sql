
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 2: Data Cleaning & Quality
-- STEP 8: Customer Cleaning & Standardisation
--
-- PURPOSE:
-- Create a reusable cleaned analytical view for customers.
--
-- IMPORTANT:
-- Original customer records are not modified or deleted.
-- Missing and invalid location fields are flagged.
-- =====================================================

-- SECTION 1: Create the cleaned customer view.
CREATE OR REPLACE VIEW olist.vw_customers_cleaned AS

SELECT
    -- Preserve both customer identifiers.
    c.customer_id,
    c.customer_unique_id,

    -- Standardise ZIP code formatting.
    NULLIF(
        TRIM(c.customer_zip_code_prefix),
        ''
    ) AS customer_zip_code_prefix,

    -- Standardise city names.
    NULLIF(
        INITCAP(TRIM(c.customer_city)),
        ''
    ) AS customer_city,

    -- Standardise state codes.
    NULLIF(
        UPPER(TRIM(c.customer_state)),
        ''
    ) AS customer_state,

    -- Flag missing customer identifiers.
    CASE
        WHEN c.customer_id IS NULL
          OR TRIM(c.customer_id) = ''
            THEN TRUE
        ELSE FALSE
    END AS missing_customer_id_flag,

    CASE
        WHEN c.customer_unique_id IS NULL
          OR TRIM(c.customer_unique_id) = ''
            THEN TRUE
        ELSE FALSE
    END AS missing_unique_customer_id_flag,

    -- Flag missing location information.
    CASE
        WHEN c.customer_zip_code_prefix IS NULL
          OR TRIM(c.customer_zip_code_prefix) = ''
            THEN TRUE
        ELSE FALSE
    END AS missing_zip_code_flag,

    CASE
        WHEN c.customer_city IS NULL
          OR TRIM(c.customer_city) = ''
            THEN TRUE
        ELSE FALSE
    END AS missing_city_flag,

    CASE
        WHEN c.customer_state IS NULL
          OR TRIM(c.customer_state) = ''
            THEN TRUE
        ELSE FALSE
    END AS missing_state_flag,

    -- Validate five-digit numeric ZIP prefixes.
    CASE
        WHEN c.customer_zip_code_prefix IS NOT NULL
         AND TRIM(c.customer_zip_code_prefix) <> ''
         AND TRIM(c.customer_zip_code_prefix) !~ '^[0-9]{5}$'
            THEN TRUE
        ELSE FALSE
    END AS invalid_zip_code_flag,

    -- Validate two-letter uppercase state codes.
    CASE
        WHEN c.customer_state IS NOT NULL
         AND TRIM(c.customer_state) <> ''
         AND UPPER(TRIM(c.customer_state)) !~ '^[A-Z]{2}$'
            THEN TRUE
        ELSE FALSE
    END AS invalid_state_code_flag,

    -- Assign an overall customer data-quality status.
    CASE
        WHEN c.customer_id IS NULL
          OR c.customer_unique_id IS NULL
          OR c.customer_zip_code_prefix IS NULL
          OR TRIM(c.customer_zip_code_prefix) = ''
          OR c.customer_city IS NULL
          OR TRIM(c.customer_city) = ''
          OR c.customer_state IS NULL
          OR TRIM(c.customer_state) = ''
          OR (
              c.customer_zip_code_prefix IS NOT NULL
              AND TRIM(c.customer_zip_code_prefix) <> ''
              AND TRIM(c.customer_zip_code_prefix) !~ '^[0-9]{5}$'
          )
          OR (
              c.customer_state IS NOT NULL
              AND TRIM(c.customer_state) <> ''
              AND UPPER(TRIM(c.customer_state)) !~ '^[A-Z]{2}$'
          )
            THEN 'Requires Review'

        ELSE 'No Detected Issue'
    END AS customer_quality_status

FROM olist.customers c;


-- SECTION 2: Validate the cleaned customer view.
SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE missing_customer_id_flag
    ) AS missing_customer_ids,

    COUNT(*) FILTER (
        WHERE missing_unique_customer_id_flag
    ) AS missing_unique_customer_ids,

    COUNT(*) FILTER (
        WHERE missing_zip_code_flag
    ) AS missing_zip_codes,

    COUNT(*) FILTER (
        WHERE missing_city_flag
    ) AS missing_cities,

    COUNT(*) FILTER (
        WHERE missing_state_flag
    ) AS missing_states,

    COUNT(*) FILTER (
        WHERE invalid_zip_code_flag
    ) AS invalid_zip_codes,

    COUNT(*) FILTER (
        WHERE invalid_state_code_flag
    ) AS invalid_state_codes,

    COUNT(*) FILTER (
        WHERE customer_quality_status = 'Requires Review'
    ) AS customers_requiring_review

FROM olist.vw_customers_cleaned;
