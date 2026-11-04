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
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 5: RFM Customer Segmentation
-- STEP 27: RFM Quintile Scoring
-- PURPOSE:
-- Assign Recency, Frequency and Monetary scores
-- from 1 to 5 using NTILE(5).
-- =====================================================

-- STEP 1: Calculate customer-level RFM metrics
WITH customer_rfm AS (

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
),

-- STEP 2: Identify dataset snapshot date
dataset_snapshot AS (

    SELECT
        MAX(order_purchase_timestamp)::DATE AS snapshot_date

    FROM olist.orders
),

-- STEP 3: Calculate raw Recency, Frequency and Monetary
rfm_metrics AS (

    SELECT
        cr.customer_unique_id,

        -- Days since last delivered purchase
        ds.snapshot_date - cr.last_purchase_date AS recency,

        cr.frequency,
        cr.monetary

    FROM customer_rfm cr

    CROSS JOIN dataset_snapshot ds
),

-- STEP 4: Assign quintile scores to all three metrics
rfm_scoring AS (

    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,

        -- Lower recency days receive higher scores
        NTILE(5) OVER (
            ORDER BY recency DESC
        ) AS r_score,

        -- Higher frequency receives higher scores
        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS f_score,

        -- Higher monetary value receives higher scores
        NTILE(5) OVER (
            ORDER BY monetary ASC
        ) AS m_score

    FROM rfm_metrics
)

-- STEP 5: Display final RFM scores
SELECT
    customer_unique_id,
    recency,
    frequency,

    ROUND(monetary, 2) AS monetary,

    r_score,
    f_score,
    m_score,

    -- Combine three individual scores into RFM score
    CONCAT(
        r_score,
        f_score,
        m_score
    ) AS rfm_score

FROM rfm_scoring

ORDER BY
    r_score DESC,
    f_score DESC,
    m_score DESC;
    -- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 5: RFM Customer Segmentation
-- STEP 27D: Final RFM Scoring Validation
-- PURPOSE:
-- Validate customer counts, score ranges and
-- frequency-to-score consistency.
-- =====================================================

-- STEP 1: Calculate customer-level RFM metrics
WITH customer_rfm AS (

    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp)::DATE AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price) AS monetary

    FROM olist.customers c

    INNER JOIN olist.orders o
        ON c.customer_id = o.customer_id

    INNER JOIN olist.order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

-- STEP 2: Get dataset snapshot date
dataset_snapshot AS (

    SELECT MAX(order_purchase_timestamp)::DATE AS snapshot_date
    FROM olist.orders
),

-- STEP 3: Calculate RFM values
rfm_metrics AS (

    SELECT
        cr.customer_unique_id,
        ds.snapshot_date - cr.last_purchase_date AS recency,
        cr.frequency,
        cr.monetary

    FROM customer_rfm cr
    CROSS JOIN dataset_snapshot ds
),

-- STEP 4: Calculate percentile thresholds
rfm_cutoffs AS (

    SELECT
        PERCENTILE_CONT(0.20)
            WITHIN GROUP (ORDER BY recency) AS r_p20,

        PERCENTILE_CONT(0.40)
            WITHIN GROUP (ORDER BY recency) AS r_p40,

        PERCENTILE_CONT(0.60)
            WITHIN GROUP (ORDER BY recency) AS r_p60,

        PERCENTILE_CONT(0.80)
            WITHIN GROUP (ORDER BY recency) AS r_p80,

        PERCENTILE_CONT(0.20)
            WITHIN GROUP (ORDER BY monetary) AS m_p20,

        PERCENTILE_CONT(0.40)
            WITHIN GROUP (ORDER BY monetary) AS m_p40,

        PERCENTILE_CONT(0.60)
            WITHIN GROUP (ORDER BY monetary) AS m_p60,

        PERCENTILE_CONT(0.80)
            WITHIN GROUP (ORDER BY monetary) AS m_p80

    FROM rfm_metrics
),

-- STEP 5: Assign final RFM scores
rfm_scoring AS (

    SELECT
        rm.customer_unique_id,
        rm.frequency,

        CASE
            WHEN rm.recency <= rc.r_p20 THEN 5
            WHEN rm.recency <= rc.r_p40 THEN 4
            WHEN rm.recency <= rc.r_p60 THEN 3
            WHEN rm.recency <= rc.r_p80 THEN 2
            ELSE 1
        END AS r_score,

        CASE
            WHEN rm.frequency = 1 THEN 1
            WHEN rm.frequency = 2 THEN 2
            WHEN rm.frequency BETWEEN 3 AND 4 THEN 3
            WHEN rm.frequency BETWEEN 5 AND 6 THEN 4
            ELSE 5
        END AS f_score,

        CASE
            WHEN rm.monetary <= rc.m_p20 THEN 1
            WHEN rm.monetary <= rc.m_p40 THEN 2
            WHEN rm.monetary <= rc.m_p60 THEN 3
            WHEN rm.monetary <= rc.m_p80 THEN 4
            ELSE 5
        END AS m_score

    FROM rfm_metrics rm
    CROSS JOIN rfm_cutoffs rc
)

-- STEP 6: Validate overall RFM score ranges
SELECT
    COUNT(*) AS total_customers,

    MIN(r_score) AS min_r_score,
    MAX(r_score) AS max_r_score,

    MIN(f_score) AS min_f_score,
    MAX(f_score) AS max_f_score,

    MIN(m_score) AS min_m_score,
    MAX(m_score) AS max_m_score,

    COUNT(*) FILTER (
        WHERE r_score NOT BETWEEN 1 AND 5
           OR f_score NOT BETWEEN 1 AND 5
           OR m_score NOT BETWEEN 1 AND 5
    ) AS invalid_score_records

FROM rfm_scoring;