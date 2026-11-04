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
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 3: Customer Retention & Churn Analysis
-- STEP 16: Customer Inactivity Distribution
-- PURPOSE:
-- Classify delivered customers into recency buckets
-- using the dataset snapshot date.
-- =====================================================

-- STEP 1: Identify the dataset snapshot date
WITH dataset_snapshot AS (

    SELECT
        MAX(order_purchase_timestamp)::DATE AS snapshot_date
    FROM olist.orders
),

-- STEP 2: Calculate each customer's last delivered purchase
customer_last_purchase AS (

    SELECT
        c.customer_unique_id,

        MAX(o.order_purchase_timestamp)::DATE AS last_purchase_date

    FROM olist.customers c

    INNER JOIN olist.orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

-- STEP 3: Calculate recency in days
customer_recency AS (

    SELECT
        clp.customer_unique_id,

        ds.snapshot_date,

        clp.last_purchase_date,

        -- Calculate days since last delivered purchase
        ds.snapshot_date - clp.last_purchase_date AS recency_days

    FROM customer_last_purchase clp

    CROSS JOIN dataset_snapshot ds
),

-- STEP 4: Assign customers to inactivity buckets
recency_segments AS (

    SELECT
        customer_unique_id,
        recency_days,

        CASE
            WHEN recency_days <= 30 THEN 'Very Recent'
            WHEN recency_days <= 90 THEN 'Recent'
            WHEN recency_days <= 180 THEN 'Moderate'
            WHEN recency_days <= 365 THEN 'At Risk'
            WHEN recency_days <= 540 THEN 'High Risk'
            ELSE 'Long Inactive'
        END AS recency_segment

    FROM customer_recency
)

-- STEP 5: Summarize customer distribution
SELECT
    recency_segment,

    -- Count customers in each bucket
    COUNT(*) AS total_customers,

    -- Percentage of all delivered customers
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage,

    -- Average inactivity days within each bucket
    ROUND(AVG(recency_days), 2) AS avg_recency_days

FROM recency_segments

GROUP BY recency_segment

-- Keep buckets in logical chronological order
ORDER BY
    CASE recency_segment
        WHEN 'Very Recent' THEN 1
        WHEN 'Recent' THEN 2
        WHEN 'Moderate' THEN 3
        WHEN 'At Risk' THEN 4
        WHEN 'High Risk' THEN 5
        WHEN 'Long Inactive' THEN 6
    END;