
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- TABLE: product_category_translation
-- FILE: 19_validate_product_category_translation.sql
-- PURPOSE: Translation data quality and matching
-- =====================================================


-- 1. Overall translation validation

SELECT
    COUNT(*) AS total_translations,
    COUNT(DISTINCT product_category_name)
        AS unique_portuguese_categories,
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS null_portuguese_names,
    COUNT(*) FILTER (
        WHERE product_category_name_english IS NULL
    ) AS null_english_names
FROM olist.product_category_translation;


-- 2. Product category matching

SELECT
    COUNT(DISTINCT p.product_category_name)
        AS product_categories,
    COUNT(DISTINCT t.product_category_name)
        AS translated_categories,
    COUNT(DISTINCT p.product_category_name)
        FILTER (
            WHERE t.product_category_name IS NULL
        ) AS untranslated_categories
FROM olist.products p
LEFT JOIN olist.product_category_translation t
    ON p.product_category_name = t.product_category_name;


-- 3. Identify untranslated categories

SELECT
    p.product_category_name,
    COUNT(*) AS total_products
FROM olist.products p
LEFT JOIN olist.product_category_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY total_products DESC;
