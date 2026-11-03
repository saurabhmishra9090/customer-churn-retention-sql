
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- TABLE: order_reviews
-- FILE: 11_validate_order_reviews.sql
-- PURPOSE: Data Quality Validation & Review Analysis
-- =====================================================


-- 1. OVERALL DATA VALIDATION
-- Check total records, unique IDs and invalid values

SELECT
    COUNT(*) AS total_reviews,
    COUNT(DISTINCT review_record_id) AS unique_record_ids,
    COUNT(*) FILTER (
        WHERE review_id IS NULL
    ) AS null_review_ids,
    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS null_order_ids,
    COUNT(*) FILTER (
        WHERE review_score NOT BETWEEN 1 AND 5
    ) AS invalid_scores
FROM olist.order_reviews;


-- 2. REVIEW SCORE DISTRIBUTION
-- Understand customer satisfaction levels

SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM olist.order_reviews
GROUP BY review_score
ORDER BY review_score;


-- 3. FOREIGN KEY VALIDATION
-- Check reviews without matching orders

SELECT
    COUNT(*) AS unmatched_orders
FROM olist.order_reviews r
LEFT JOIN olist.orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 4. REVIEW DATE RANGE
-- Identify earliest and latest review dates

SELECT
    MIN(review_creation_date) AS first_review_date,
    MAX(review_creation_date) AS last_review_date
FROM olist.order_reviews;


-- 5. REVIEW SCORE SUMMARY
-- Calculate average customer rating

SELECT
    ROUND(AVG(review_score), 2) AS average_review_score,
    COUNT(*) AS total_reviews,
    COUNT(*) FILTER (
        WHERE review_score IN (1, 2)
    ) AS negative_reviews,
    COUNT(*) FILTER (
        WHERE review_score IN (4, 5)
    ) AS positive_reviews
FROM olist.order_reviews;
