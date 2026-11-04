-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 5: RFM Customer Segmentation
-- STEP 26: Customer-Level RFM Base Table
-- PURPOSE:
-- Calculate Recency, Frequency and Monetary values
-- for every unique customer with delivered purchases.
-- =====================================================

-- STEP 1: Identify the dataset snapshot date
WITH dataset_snapshot AS (

    SELECT
        MAX(order_purchase_timestamp)::DATE AS snapshot_date

    FROM olist.orders
),

-- STEP 2: Calculate customer-level RFM metrics
customer_rfm AS (

    SELECT
        c.customer_unique_id,

        -- Most recent delivered purchase date
        MAX(o.order_purchase_timestamp)::DATE AS last_purchase_date,

        -- Number of distinct delivered orders
        COUNT(DISTINCT o.order_id) AS frequency,

        -- Total delivered product revenue
        SUM(oi.price) AS monetary

    FROM olist.customers c

    INNER JOIN olist.orders o
        ON c.customer_id = o.customer_id

    INNER JOIN olist.order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
)

-- STEP 3: Calculate final RFM metrics
SELECT
    cr.customer_unique_id,

    -- Days since the customer's last delivered purchase
    ds.snapshot_date - cr.last_purchase_date AS recency,

    cr.frequency,

    -- Total product revenue per customer
    ROUND(cr.monetary, 2) AS monetary

FROM customer_rfm cr

CROSS JOIN dataset_snapshot ds

ORDER BY cr.customer_unique_id;
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 5: RFM Customer Segmentation
-- STEP 26: RFM Base Table Validation
-- PURPOSE:
-- Validate customer count, recency, frequency
-- and monetary values across the complete RFM dataset.
-- =====================================================

-- STEP 1: Calculate customer-level RFM metrics
WITH customer_rfm AS (

    SELECT
        c.customer_unique_id,

        -- Most recent delivered purchase date
        MAX(o.order_purchase_timestamp)::DATE AS last_purchase_date,

        -- Count distinct delivered orders
        COUNT(DISTINCT o.order_id) AS frequency,

        -- Calculate total delivered product revenue
        SUM(oi.price) AS monetary

    FROM olist.customers c

    INNER JOIN olist.orders o
        ON c.customer_id = o.customer_id

    INNER JOIN olist.order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

-- STEP 2: Identify dataset snapshot date
dataset_snapshot AS (

    SELECT
        MAX(order_purchase_timestamp)::DATE AS snapshot_date

    FROM olist.orders
)

-- STEP 3: Validate complete RFM dataset
SELECT
    -- Total unique delivered customers
    COUNT(*) AS total_customers,

    -- Minimum and maximum recency
    MIN(ds.snapshot_date - cr.last_purchase_date) AS min_recency,
    MAX(ds.snapshot_date - cr.last_purchase_date) AS max_recency,

    -- Average recency
    ROUND(
        AVG(ds.snapshot_date - cr.last_purchase_date),
        2
    ) AS avg_recency,

    -- Minimum and maximum purchase frequency
    MIN(cr.frequency) AS min_frequency,
    MAX(cr.frequency) AS max_frequency,

    -- Average purchase frequency
    ROUND(AVG(cr.frequency), 2) AS avg_frequency,

    -- Total delivered product revenue
    ROUND(SUM(cr.monetary), 2) AS total_monetary,

    -- Average revenue per customer
    ROUND(AVG(cr.monetary), 2) AS avg_monetary

FROM customer_rfm cr

CROSS JOIN dataset_snapshot ds;