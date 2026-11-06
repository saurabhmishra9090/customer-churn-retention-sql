
-- ============================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 3: Query Performance Optimization
-- STEP 6: Optimization Summary
--
-- PURPOSE:
-- Consolidate index and memory optimization experiments.
-- Document measured improvements and technical observations.
--
-- IMPORTANT:
-- These are observed test results, not guaranteed timings.
-- Execution time can vary with cache and system workload.
-- ============================================================


-- SECTION 1: Index optimization experiment summary.
-- Candidate index: idx_orders_customer_id
-- Table: olist.orders
-- Column: customer_id

SELECT
    'Index Optimization' AS experiment,
    'Customer ID Lookup' AS test_name,
    11.624 AS before_execution_ms,
    0.161 AS after_execution_ms,
    ROUND(
        ((11.624 - 0.161) / 11.624) * 100,
        2
    ) AS improvement_pct,
    'Index Scan replaced Sequential Scan' AS observation

UNION ALL

-- SECTION 2: Revenue aggregation performance.
-- Comparison: 4MB vs 16MB work_mem.

SELECT
    'Memory Optimization',
    'Q2 Revenue Aggregation',
    2355.693,
    1930.233,
    ROUND(
        ((2355.693 - 1930.233) / 2355.693) * 100,
        2
    ),
    'External Merge replaced by Quicksort'

UNION ALL

-- SECTION 3: Customer purchase history performance.
-- Comparison: 4MB vs 16MB work_mem.

SELECT
    'Memory Optimization',
    'Q3 Customer Purchase History',
    2143.999,
    1633.305,
    ROUND(
        ((2143.999 - 1633.305) / 2143.999) * 100,
        2
    ),
    'External Merge replaced by Quicksort';


-- SECTION 4: Important technical findings.
-- These observations explain the limitations of the tests.

SELECT
    'Index Findings' AS finding_area,
    'The candidate customer_id index improved a selective lookup.'
        AS finding

UNION ALL

SELECT
    'Index Findings',
    'Full-table analytical queries continued to use sequential scans.'

UNION ALL

SELECT
    'Index Findings',
    'Payment aggregation used the existing primary-key index.'

UNION ALL

SELECT
    'Memory Findings',
    'Increasing session work_mem from 4MB to 16MB eliminated disk sorting in Q2 and Q3.'

UNION ALL

SELECT
    'Memory Findings',
    'The work_mem setting was restored to its original 4MB value.'

UNION ALL

SELECT
    'Limitations',
    'One analytical query became slower after index testing.'

UNION ALL

SELECT
    'Limitations',
    'Execution times can vary due to cache state and system workload.'

UNION ALL

SELECT
    'Limitations',
    'The 16MB setting was tested on two queries only; it is not a universal optimum.';


-- ============================================================
-- END OF OPTIMIZATION SUMMARY
-- ============================================================
