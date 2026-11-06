
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 3: Query Performance Optimization
-- STEP 4: After-Index Performance Testing
--
-- PURPOSE:
-- Re-run the same five baseline analytical queries
-- after creating idx_orders_customer_id.
--
-- COMPARISON:
-- Compare execution times with Step 1 baseline.
--
-- IMPORTANT:
-- Query logic is intentionally unchanged.
-- No additional indexes are created in this file.
-- =====================================================


-- SECTION 1: Customer and Orders JOIN.
-- Baseline execution time: 1130.718 ms

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.customer_unique_id,
    COUNT(o.order_id) AS total_orders
FROM olist.customers c
JOIN olist.orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id;


-- SECTION 2: Order Items Revenue Aggregation.
-- Baseline execution time: 3425.249 ms

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue
FROM olist.orders o
JOIN olist.order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.order_status;


-- SECTION 3: Customer Purchase History.
-- Baseline execution time: 2685.350 ms

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.customer_unique_id,
    MAX(o.order_purchase_timestamp) AS last_purchase_date,
    COUNT(DISTINCT o.order_id) AS delivered_orders
FROM olist.customers c
JOIN olist.orders o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id;


-- SECTION 4: Payment Aggregation.
-- Baseline execution time: 1116.282 ms

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_id,
    SUM(payment_value) AS total_payment_value,
    COUNT(*) AS payment_record_count
FROM olist.order_payments
GROUP BY order_id;


-- SECTION 5: Product Category Analysis.
-- Baseline execution time: 55.969 ms

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,
    COUNT(*) AS total_products
FROM olist.products p
LEFT JOIN olist.product_category_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown'
    );

-- =====================================================
-- SECTION 6: BEFORE VS AFTER PERFORMANCE RESULTS
--
-- Query                         Before       After
-- Customer-Orders JOIN          1130.718     875.118
-- Revenue Aggregation           3425.249     2259.165
-- Customer Purchase History     2685.350     2590.967
-- Payment Aggregation           1116.282      357.361
-- Product Category Analysis       55.969       68.079
--
-- Observations:
-- Q1 improved by approximately 22.6%.
-- Q2 improved by approximately 34.0%.
-- Q3 improved by approximately 3.5%.
-- Q4 improved by approximately 68.0%.
-- Q5 became approximately 21.6% slower.
--
-- The candidate customer_id index was not selected
-- in the full-table analytical query plans.
--
-- Q4 used the existing payment primary-key index.
-- External merge sorting remains in Q2 and Q3.
--
-- NOTE:
-- Execution times are individual observations.
-- Cache state and system load can affect timings.
-- Results should be reproduced before drawing
-- definitive performance conclusions.
-- =====================================================
