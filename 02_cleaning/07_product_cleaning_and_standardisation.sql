
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 2: Data Cleaning & Quality
-- STEP 7: Product Cleaning & Standardisation
--
-- PURPOSE:
-- Create a reusable cleaned analytical view for products.
--
-- IMPORTANT:
-- Original product records are not modified or deleted.
-- Missing and invalid attributes are flagged.
-- =====================================================

-- SECTION 1: Create the cleaned product view.
CREATE OR REPLACE VIEW olist.vw_products_cleaned AS

SELECT
    -- Preserve the original product identifier.
    p.product_id,

    -- Preserve the original Portuguese category.
    NULLIF(
        LOWER(TRIM(p.product_category_name)),
        ''
    ) AS product_category_name,

    -- Attach English category translation where available.
    NULLIF(
        LOWER(TRIM(t.product_category_name_english)),
        ''
    ) AS product_category_name_english,

    -- Preserve original product attributes.
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,

    -- Flag missing product category.
    CASE
        WHEN p.product_category_name IS NULL
          OR TRIM(p.product_category_name) = ''
            THEN TRUE
        ELSE FALSE
    END AS missing_category_flag,

    -- Flag missing product weight.
    CASE
        WHEN p.product_weight_g IS NULL
            THEN TRUE
        ELSE FALSE
    END AS missing_weight_flag,

    -- Flag zero or negative product weight.
    CASE
        WHEN p.product_weight_g <= 0
            THEN TRUE
        ELSE FALSE
    END AS invalid_weight_flag,

    -- Flag missing product dimensions.
    CASE
        WHEN p.product_length_cm IS NULL
          OR p.product_height_cm IS NULL
          OR p.product_width_cm IS NULL
            THEN TRUE
        ELSE FALSE
    END AS missing_dimensions_flag,

    -- Flag invalid product dimensions.
    CASE
        WHEN p.product_length_cm <= 0
          OR p.product_height_cm <= 0
          OR p.product_width_cm <= 0
            THEN TRUE
        ELSE FALSE
    END AS invalid_dimensions_flag,

    -- Flag missing product description attributes.
    CASE
        WHEN p.product_name_lenght IS NULL
          OR p.product_description_lenght IS NULL
          OR p.product_photos_qty IS NULL
            THEN TRUE
        ELSE FALSE
    END AS missing_description_attributes_flag,

    -- Flag missing English category translation.
    CASE
        WHEN p.product_category_name IS NOT NULL
         AND t.product_category_name IS NULL
            THEN TRUE
        ELSE FALSE
    END AS missing_translation_flag,

    -- Classify product category availability.
    CASE
        WHEN p.product_category_name IS NULL
          OR TRIM(p.product_category_name) = ''
            THEN 'Missing Category'

        WHEN t.product_category_name IS NULL
            THEN 'Translation Unavailable'

        ELSE 'Translated Category'
    END AS category_translation_status,

    -- Assign an overall product data-quality status.
    CASE
        WHEN p.product_weight_g IS NULL
          OR p.product_weight_g <= 0
          OR p.product_length_cm IS NULL
          OR p.product_height_cm IS NULL
          OR p.product_width_cm IS NULL
          OR p.product_length_cm <= 0
          OR p.product_height_cm <= 0
          OR p.product_width_cm <= 0
          OR p.product_category_name IS NULL
          OR TRIM(p.product_category_name) = ''
            THEN 'Requires Attribute Review'

        WHEN t.product_category_name IS NULL
            THEN 'Requires Translation Review'

        ELSE 'No Detected Critical Issue'
    END AS product_quality_status

FROM olist.products p

LEFT JOIN olist.product_category_translation t
    ON p.product_category_name = t.product_category_name;


-- SECTION 2: Validate the cleaned product view.
SELECT
    COUNT(*) AS total_products,

    COUNT(*) FILTER (
        WHERE missing_category_flag
    ) AS missing_categories,

    COUNT(*) FILTER (
        WHERE missing_weight_flag
    ) AS missing_weights,

    COUNT(*) FILTER (
        WHERE invalid_weight_flag
    ) AS invalid_weights,

    COUNT(*) FILTER (
        WHERE missing_dimensions_flag
    ) AS missing_dimensions,

    COUNT(*) FILTER (
        WHERE missing_translation_flag
    ) AS missing_translations,

    COUNT(*) FILTER (
        WHERE product_quality_status = 'Requires Attribute Review'
    ) AS products_requiring_attribute_review,

    COUNT(*) FILTER (
        WHERE product_quality_status = 'Requires Translation Review'
    ) AS products_requiring_translation_review

FROM olist.vw_products_cleaned;
