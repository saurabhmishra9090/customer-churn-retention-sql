
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 3: Query Performance Optimization
-- STEP 3: Candidate Index Testing
--
-- PURPOSE:
-- Test whether an index on orders.customer_id
-- improves selective customer-order lookups.
--
-- IMPORTANT:
-- Original table records are not modified.
-- The index is an additional database structure.
-- =====================================================


-- SECTION 1: Baseline query WITHOUT the candidate index.
-- This query retrieves orders for one customer.
-- The customer is selected deterministically.

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    o.order_id,
    o.customer_id,
    o.order_purchase_timestamp,
    o.order_status

FROM olist.orders o

WHERE o.customer_id = (
    SELECT c.customer_id
    FROM olist.customers c
    ORDER BY c.customer_id
    LIMIT 1
);


-- SECTION 2: Create the candidate index.
-- This index supports lookups by customer_id.

CREATE INDEX IF NOT EXISTS idx_orders_customer_id
ON olist.orders (customer_id);


-- SECTION 3: Refresh table statistics.
-- PostgreSQL uses these statistics to choose query plans.

ANALYZE olist.orders;


-- SECTION 4: Repeat the SAME query WITH the index.
-- Compare the execution plan and execution time
-- against Section 1.

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    o.order_id,
    o.customer_id,
    o.order_purchase_timestamp,
    o.order_status

FROM olist.orders o

WHERE o.customer_id = (
    SELECT c.customer_id
    FROM olist.customers c
    ORDER BY c.customer_id
    LIMIT 1
);


-- SECTION 5: Verify that the candidate index exists.

SELECT
    schemaname,
    tablename,
    indexname,
    indexdef

FROM pg_indexes

WHERE schemaname = 'olist'
  AND tablename = 'orders'
  AND indexname = 'idx_orders_customer_id';

-- =====================================================
-- SECTION 6: CANDIDATE INDEX TEST RESULTS
--
-- Tested index:
-- idx_orders_customer_id
--
-- Tested column:
-- olist.orders.customer_id
--
-- BEFORE INDEX:
-- Scan Method: Sequential Scan
-- Execution Time: 11.624 ms
-- Rows Removed by Filter: 99,440
--
-- AFTER INDEX:
-- Scan Method: Index Scan
-- Execution Time: 0.161 ms
--
-- Observed execution-time reduction: approximately 98.61%
-- Observed speed improvement: approximately 72x
--
-- NOTE:
-- Timings are from individual test executions.
-- Actual performance can vary with cache state,
-- system load and repeated execution.
--
-- RESULT:
-- Candidate index successfully created and used
-- by PostgreSQL for the selective customer lookup.
-- =====================================================
