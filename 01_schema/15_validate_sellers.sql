
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- TABLE: sellers
-- FILE: 14_validate_sellers.sql
-- PURPOSE: Seller data quality and integrity checks
-- =====================================================


-- 1. Overall seller validation

SELECT
    COUNT(*) AS total_sellers,
    COUNT(DISTINCT seller_id) AS unique_sellers,
    COUNT(*) FILTER (
        WHERE seller_id IS NULL
    ) AS null_seller_ids,
    COUNT(*) FILTER (
        WHERE seller_city IS NULL
    ) AS null_cities,
    COUNT(*) FILTER (
        WHERE seller_state IS NULL
    ) AS null_states
FROM olist.sellers;


-- 2. Seller state distribution

SELECT
    seller_state,
    COUNT(*) AS total_sellers
FROM olist.sellers
GROUP BY seller_state
ORDER BY total_sellers DESC;


-- 3. Seller city distribution

SELECT
    seller_city,
    seller_state,
    COUNT(*) AS total_sellers
FROM olist.sellers
GROUP BY seller_city, seller_state
ORDER BY total_sellers DESC;


-- 4. Foreign key validation

SELECT
    COUNT(*) AS unmatched_seller_records
FROM olist.order_items oi
LEFT JOIN olist.sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;
