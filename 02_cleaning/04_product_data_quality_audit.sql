
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 2: Data Cleaning & Quality
-- STEP 4: Product Data Quality Audit
--
-- PURPOSE:
-- Identify missing product attributes, invalid
-- dimensions, and untranslated product categories.
--
-- IMPORTANT:
-- This is a read-only audit. No data is modified.
-- =====================================================

-- SECTION 1: Audit product records.
WITH product_quality AS (

    SELECT
        COUNT(*) AS total_products,

        -- Check missing product identifiers.
        COUNT(*) FILTER (
            WHERE p.product_id IS NULL
        ) AS null_product_ids,

        -- Check missing product categories.
        COUNT(*) FILTER (
            WHERE p.product_category_name IS NULL
        ) AS null_categories,

        -- Check missing product attributes.
        COUNT(*) FILTER (
            WHERE p.product_name_lenght IS NULL
        ) AS null_name_lengths,

        COUNT(*) FILTER (
            WHERE p.product_description_lenght IS NULL
        ) AS null_description_lengths,

        COUNT(*) FILTER (
            WHERE p.product_photos_qty IS NULL
        ) AS null_photo_counts,

        COUNT(*) FILTER (
            WHERE p.product_weight_g IS NULL
        ) AS null_weights,

        COUNT(*) FILTER (
            WHERE p.product_length_cm IS NULL
        ) AS null_lengths,

        COUNT(*) FILTER (
            WHERE p.product_height_cm IS NULL
        ) AS null_heights,

        COUNT(*) FILTER (
            WHERE p.product_width_cm IS NULL
        ) AS null_widths,

        -- Identify non-positive product attributes.
        COUNT(*) FILTER (
            WHERE p.product_name_lenght <= 0
        ) AS non_positive_name_lengths,

        COUNT(*) FILTER (
            WHERE p.product_description_lenght <= 0
        ) AS non_positive_description_lengths,

        COUNT(*) FILTER (
            WHERE p.product_photos_qty <= 0
        ) AS non_positive_photo_counts,

        COUNT(*) FILTER (
            WHERE p.product_weight_g <= 0
        ) AS non_positive_weights,

        COUNT(*) FILTER (
            WHERE p.product_length_cm <= 0
        ) AS non_positive_lengths,

        COUNT(*) FILTER (
            WHERE p.product_height_cm <= 0
        ) AS non_positive_heights,

        COUNT(*) FILTER (
            WHERE p.product_width_cm <= 0
        ) AS non_positive_widths,

        -- Check product category translation.
        COUNT(*) FILTER (
            WHERE p.product_category_name IS NOT NULL
              AND t.product_category_name IS NULL
        ) AS untranslated_products

    FROM olist.products p

    LEFT JOIN olist.product_category_translation t
        ON p.product_category_name = t.product_category_name
)

-- SECTION 2: Display product audit results.
SELECT
    'Total Products' AS quality_check,
    total_products::TEXT AS result,
    'Reference count of product records' AS interpretation
FROM product_quality

UNION ALL

SELECT
    'NULL Product IDs',
    null_product_ids::TEXT,
    'Expected: 0'
FROM product_quality

UNION ALL

SELECT
    'NULL Categories',
    null_categories::TEXT,
    'Missing product category information'
FROM product_quality

UNION ALL

SELECT
    'NULL Name Lengths',
    null_name_lengths::TEXT,
    'Missing product name length'
FROM product_quality

UNION ALL

SELECT
    'NULL Description Lengths',
    null_description_lengths::TEXT,
    'Missing product description length'
FROM product_quality

UNION ALL

SELECT
    'NULL Photo Counts',
    null_photo_counts::TEXT,
    'Missing product photo information'
FROM product_quality

UNION ALL

SELECT
    'NULL Weights',
    null_weights::TEXT,
    'Missing product weight information'
FROM product_quality

UNION ALL

SELECT
    'NULL Lengths',
    null_lengths::TEXT,
    'Missing product length information'
FROM product_quality

UNION ALL

SELECT
    'NULL Heights',
    null_heights::TEXT,
    'Missing product height information'
FROM product_quality

UNION ALL

SELECT
    'NULL Widths',
    null_widths::TEXT,
    'Missing product width information'
FROM product_quality

UNION ALL

SELECT
    'Non-positive Name Lengths',
    non_positive_name_lengths::TEXT,
    'Investigate zero or negative values'
FROM product_quality

UNION ALL

SELECT
    'Non-positive Description Lengths',
    non_positive_description_lengths::TEXT,
    'Investigate zero or negative values'
FROM product_quality

UNION ALL

SELECT
    'Non-positive Photo Counts',
    non_positive_photo_counts::TEXT,
    'Investigate zero or negative values'
FROM product_quality

UNION ALL

SELECT
    'Non-positive Weights',
    non_positive_weights::TEXT,
    'Investigate zero or negative weights'
FROM product_quality

UNION ALL

SELECT
    'Non-positive Lengths',
    non_positive_lengths::TEXT,
    'Investigate invalid product lengths'
FROM product_quality

UNION ALL

SELECT
    'Non-positive Heights',
    non_positive_heights::TEXT,
    'Investigate invalid product heights'
FROM product_quality

UNION ALL

SELECT
    'Non-positive Widths',
    non_positive_widths::TEXT,
    'Investigate invalid product widths'
FROM product_quality

UNION ALL

SELECT
    'Untranslated Products',
    untranslated_products::TEXT,
    'Products without English category translation'
FROM product_quality;
-- =====================================================
-- SECTION 3: PRODUCT INVESTIGATION FINDINGS
--
-- PRODUCT ATTRIBUTE ISSUES:
-- Total affected products: 6
-- Missing weights: 2
-- Zero weights: 4
-- Missing dimensions: 2 records for each dimension
--
-- CATEGORY TRANSLATION ISSUES:
-- Untranslated products: 13
--
-- Missing Portuguese categories:
-- 1. portateis_cozinha_e_preparadores_de_alimentos: 10
-- 2. pc_gamer: 3
--
-- BUSINESS INTERPRETATION:
-- Missing and zero product weights require investigation.
-- Missing dimensions may affect shipping analysis.
-- Untranslated categories limit English-language reporting.
--
-- FINAL CLEANING DECISION:
-- Preserve original product records.
-- Do not invent missing product attributes.
-- Do not delete untranslated category records.
-- Preserve original Portuguese category names.
-- =====================================================