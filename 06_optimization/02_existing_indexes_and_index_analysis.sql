
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 3: Query Performance Optimization
-- STEP 2: Existing Indexes & Index Analysis
--
-- PURPOSE:
-- Inspect existing indexes, primary keys and index usage.
--
-- IMPORTANT:
-- Read-only analysis. No indexes are created or deleted.
-- =====================================================

-- SECTION 1: List all existing indexes on project tables.
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef

FROM pg_indexes

WHERE schemaname = 'olist'

ORDER BY
    tablename,
    indexname;


-- SECTION 2: Inspect primary keys and unique constraints.
SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name

FROM information_schema.table_constraints tc

LEFT JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema = kcu.table_schema

WHERE tc.table_schema = 'olist'
  AND tc.constraint_type IN ('PRIMARY KEY', 'UNIQUE')

ORDER BY
    tc.table_name,
    tc.constraint_type,
    kcu.ordinal_position;


-- SECTION 3: Inspect index usage statistics.
-- Zero scans do not automatically mean an index is unnecessary.
SELECT
    s.relname AS table_name,
    s.indexrelname AS index_name,
    s.idx_scan AS index_scans,
    s.idx_tup_read AS index_tuples_read,
    s.idx_tup_fetch AS index_tuples_fetched

FROM pg_stat_user_indexes s

WHERE s.schemaname = 'olist'

ORDER BY
    s.relname,
    s.idx_scan DESC;


-- SECTION 4: Inspect table sizes and index sizes.
SELECT
    t.tablename,

    pg_size_pretty(
        pg_total_relation_size(
            format('%I.%I', t.schemaname, t.tablename)::regclass
        )
    ) AS total_table_size,

    pg_size_pretty(
        pg_indexes_size(
            format('%I.%I', t.schemaname, t.tablename)::regclass
        )
    ) AS total_index_size

FROM pg_tables t

WHERE t.schemaname = 'olist'

ORDER BY
    pg_total_relation_size(
        format('%I.%I', t.schemaname, t.tablename)::regclass
    ) DESC;

-- =====================================================
-- SECTION 5: EXISTING INDEX ANALYSIS FINDINGS
--
-- Existing primary-key indexes are available on
-- the major project tables.
--
-- orders.customer_id has no separate index.
--
-- order_items.order_id is already the first column
-- of its composite primary-key index.
--
-- order_payments.order_id is already the first column
-- of its composite primary-key index.
--
-- Q1, Q2 and Q3 use sequential scans and hash joins.
-- External merge sorting was observed in Q1, Q2 and Q3.
--
-- INDEX INVESTIGATION:
-- Evaluate orders.customer_id as a candidate index.
-- Evaluate query rewrites and sort-memory requirements.
--
-- Do not create duplicate or unnecessary indexes.
-- Verify every proposed change using EXPLAIN ANALYZE.
-- =====================================================
