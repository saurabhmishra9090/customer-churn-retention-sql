
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- TABLE: products
-- FILE: 13_validate_products.sql
-- PURPOSE: Product data quality validation
-- =====================================================


-- 1. Overall product validation

SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(*) FILTER (
        WHERE product_id IS NULL
    ) AS null_product_ids,
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS null_categories
FROM olist.products;


-- 2. Missing product attributes

SELECT
    COUNT(*) FILTER (
        WHERE product_name_lenght IS NULL
    ) AS missing_name_length,
    COUNT(*) FILTER (
        WHERE product_description_lenght IS NULL
    ) AS missing_description_length,
    COUNT(*) FILTER (
        WHERE product_photos_qty IS NULL
    ) AS missing_photos,
    COUNT(*) FILTER (
        WHERE product_weight_g IS NULL
    ) AS missing_weights,
    COUNT(*) FILTER (
        WHERE product_length_cm IS NULL
    ) AS missing_lengths,
    COUNT(*) FILTER (
        WHERE product_height_cm IS NULL
    ) AS missing_heights,
    COUNT(*) FILTER (
        WHERE product_width_cm IS NULL
    ) AS missing_widths
FROM olist.products;


-- 3. Invalid physical attributes

SELECT
    COUNT(*) FILTER (
        WHERE product_weight_g <= 0
    ) AS non_positive_weights,
    COUNT(*) FILTER (
        WHERE product_length_cm <= 0
    ) AS invalid_lengths,
    COUNT(*) FILTER (
        WHERE product_height_cm <= 0
    ) AS invalid_heights,
    COUNT(*) FILTER (
        WHERE product_width_cm <= 0
    ) AS invalid_widths
FROM olist.products;


-- 4. Product category distribution

SELECT
    product_category_name,
    COUNT(*) AS total_products
FROM olist.products
GROUP BY product_category_name
ORDER BY total_products DESC;


-- 5. Product attribute exceptions

SELECT *
FROM olist.products
WHERE product_weight_g IS NULL
   OR product_weight_g <= 0
   OR product_length_cm IS NULL
   OR product_length_cm <= 0
   OR product_height_cm IS NULL
   OR product_height_cm <= 0
   OR product_width_cm IS NULL
   OR product_width_cm <= 0;
