-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 3: Customer Retention & Churn Analysis
-- STEP 15: Customer Recency Analysis
-- PURPOSE:
-- Calculate how many days have passed since each
-- customer's last delivered purchase, using the
-- dataset's maximum purchase date as the snapshot date.
-- =====================================================

-- STEP 1: Identify the dataset snapshot date
WITH dataset_snapshot AS (

    SELECT
        -- Latest purchase date available in the dataset
        MAX(order_purchase_timestamp)::DATE AS snapshot_date

    FROM olist.orders
),

-- STEP 2: Find each customer's last delivered purchase
customer_last_purchase AS (

    SELECT
        c.customer_unique_id,

        -- Most recent delivered order purchase date
        MAX(o.order_purchase_timestamp)::DATE AS last_purchase_date,

        -- Count distinct delivered orders
        COUNT(DISTINCT o.order_id) AS delivered_orders

    FROM olist.customers c

    INNER JOIN olist.orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

-- STEP 3: Calculate customer recency
customer_recency AS (

    SELECT
        clp.customer_unique_id,
        clp.last_purchase_date,
        clp.delivered_orders,
        ds.snapshot_date,

        -- Days between last purchase and dataset snapshot
        ds.snapshot_date - clp.last_purchase_date AS recency_days

    FROM customer_last_purchase clp
    CROSS JOIN dataset_snapshot ds
)

-- STEP 4: Summarize customer recency distribution
SELECT
    -- Dataset reference date
    MAX(snapshot_date) AS snapshot_date,

    -- Total customers with delivered orders
    COUNT(*) AS total_customers,

    -- Average days since last delivered purchase
    ROUND(AVG(recency_days), 2) AS avg_recency_days,

    -- Median recency
    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY recency_days)::NUMERIC,
        2
    ) AS median_recency_days,

    -- 75th percentile of recency
    ROUND(
        PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY recency_days)::NUMERIC,
        2
    ) AS p75_recency_days,

    -- 90th percentile of recency
    ROUND(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY recency_days)::NUMERIC,
        2
    ) AS p90_recency_days,

    -- Maximum recency
    MAX(recency_days) AS maximum_recency_days

FROM customer_recency;