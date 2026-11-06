
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 3: Query Performance Optimization
-- STEP 1: Query Performance Baseline
--
-- PURPOSE:
-- Record the initial execution plans and timings
-- of representative analytical queries.
--
-- IMPORTANT:
-- Run these queries before creating new indexes.
-- No database records are modified.
-- =====================================================

-- SECTION 1: Baseline - Customer and Orders JOIN.
-- Measures the cost of joining customers and orders.

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.customer_unique_id,
    COUNT(o.order_id) AS total_orders
FROM olist.customers c
JOIN olist.orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id;


-- SECTION 2: Baseline - Order Items Revenue Aggregation.
-- Measures the cost of joining orders and order items.

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue
FROM olist.orders o
JOIN olist.order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.order_status;


-- SECTION 3: Baseline - Customer Purchase History.
-- Measures the cost of filtering delivered orders
-- and calculating the last purchase date per customer.

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


-- SECTION 4: Baseline - Payment Aggregation.
-- Measures the cost of grouping payment records by order.

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_id,
    SUM(payment_value) AS total_payment_value,
    COUNT(*) AS payment_record_count
FROM olist.order_payments
GROUP BY order_id;


-- SECTION 5: Baseline - Product Category Analysis.
-- Measures the cost of joining products with translations.

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
-- SECTION 6: BASELINE PERFORMANCE DOCUMENTATION
--
-- Execution times recorded before additional indexes.
-- Times are environment-dependent and may vary.
--
-- Q1 Customer-Orders JOIN:          1130.718 ms
-- Q2 Revenue Aggregation:           3425.249 ms
-- Q3 Customer Purchase History:     2685.350 ms
-- Q4 Payment Aggregation:           1116.282 ms
-- Q5 Product Category Analysis:       55.969 ms
--
-- Initial observations:
-- Q2 and Q3 have the highest execution times.
-- External merge sorts and temporary disk I/O
-- were observed in Q1, Q2 and Q3.
-- Q4 already uses its primary-key index.
-- Q5 has comparatively low execution time.
--
-- NEXT:
-- Investigate query plans and identify justified indexes.
-- =====================================================
