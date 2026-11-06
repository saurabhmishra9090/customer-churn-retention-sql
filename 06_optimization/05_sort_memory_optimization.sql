
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 3: Query Performance Optimization
-- STEP 5: Sort & Memory Optimization
--
-- PURPOSE:
-- Test whether increasing session work_mem reduces
-- disk-based sorting in analytical queries.
--
-- IMPORTANT:
-- This setting applies only to the current session.
-- It does not permanently change PostgreSQL settings.
-- =====================================================


-- SECTION 1: Check the current memory setting.
SHOW work_mem;


-- SECTION 2: Test Q2 with the original memory setting.
-- Baseline execution time: 3425.249 ms
-- Previous after-index time: 2259.165 ms

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue
FROM olist.orders o
JOIN olist.order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.order_status;


-- SECTION 3: Test Q3 with the original memory setting.
-- Baseline execution time: 2685.350 ms
-- Previous after-index time: 2590.967 ms

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


-- SECTION 4: Increase work_mem for this session only.
-- Test with 16 MB instead of the current setting.

SET work_mem = '16MB';


-- SECTION 5: Verify the updated session setting.
SHOW work_mem;


-- SECTION 6: Re-run Q2 with increased work_mem.
-- Check whether Sort Method changes from
-- external merge to quicksort or another in-memory method.

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue
FROM olist.orders o
JOIN olist.order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.order_status;


-- SECTION 7: Re-run Q3 with increased work_mem.

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


-- SECTION 8: Restore the original session setting.
RESET work_mem;


-- SECTION 9: Verify that the original setting is restored.
SHOW work_mem;
-- =====================================================
-- SECTION 10: PERFORMANCE COMPARISON
--
-- Query: Q2 Revenue Aggregation
-- 4MB:  2355.693 ms (External Merge, 6552 kB disk)
-- 16MB: 1930.233 ms (Quicksort, 11611 kB memory)
-- Improvement: approximately 18.0%
--
-- Query: Q3 Customer Purchase History
-- 4MB:  2143.999 ms (External Merge, 8592 kB disk)
-- 16MB: 1633.305 ms (Quicksort, 13444 kB memory)
-- Improvement: approximately 23.8%
--
-- Conclusion:
-- Increasing work_mem to 16MB eliminated disk-based
-- sorting in both tested queries and improved their
-- observed execution times.
--
-- The setting was session-level and was reset after
-- testing. No permanent server configuration changed.
--
-- Note: Execution time may vary with cache state
-- and system workload.
-- =====================================================