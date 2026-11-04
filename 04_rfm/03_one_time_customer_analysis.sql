
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 5: RFM Customer Segmentation
-- STEP 30: One-Time Customer Analysis
-- PURPOSE:
-- Analyse one-time customers by Recency and Monetary
-- scores to identify potential business segments.
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

-- STEP 2: Identify dataset snapshot date
dataset_snapshot AS (

    SELECT
        MAX(order_purchase_timestamp)::DATE AS snapshot_date
    FROM olist.orders
),

-- STEP 3: Calculate customer RFM metrics
rfm_metrics AS (

    SELECT
        cr.customer_unique_id,

        ds.snapshot_date - cr.last_purchase_date AS recency,

        cr.frequency,
        cr.monetary

    FROM customer_rfm cr
    CROSS JOIN dataset_snapshot ds
),

-- STEP 4: Calculate Recency and Monetary cutoffs
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

-- STEP 5: Assign RFM scores
rfm_scoring AS (

    SELECT
        rm.customer_unique_id,
        rm.recency,
        rm.frequency,
        rm.monetary,

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

-- STEP 6: Analyse one-time customers
SELECT
    r_score,
    m_score,

    COUNT(*) AS total_customers,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS one_time_customer_percentage,

    ROUND(SUM(monetary), 2) AS total_revenue,

    ROUND(AVG(monetary), 2) AS avg_revenue_per_customer,

    ROUND(AVG(recency), 2) AS avg_recency_days

FROM rfm_scoring

WHERE frequency = 1

GROUP BY
    r_score,
    m_score

ORDER BY
    r_score DESC,
    m_score DESC;

-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 5: RFM Customer Segmentation
-- STEP 31: One-Time Customer Business Segmentation
-- PURPOSE:
-- Divide one-time customers into actionable groups
-- based on recency and monetary scores.
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

-- STEP 2: Identify dataset snapshot date
dataset_snapshot AS (

    SELECT
        MAX(order_purchase_timestamp)::DATE AS snapshot_date
    FROM olist.orders
),

-- STEP 3: Calculate RFM metrics
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

-- STEP 5: Assign RFM scores
rfm_scoring AS (

    SELECT
        rm.customer_unique_id,
        rm.recency,
        rm.frequency,
        rm.monetary,

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
),

-- STEP 6: Classify one-time customers
one_time_segments AS (

    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,
        r_score,
        m_score,

        CASE
            WHEN m_score >= 4
                THEN 'High-Value One-Time'

            WHEN r_score >= 4
             AND m_score <= 3
                THEN 'Recent One-Time'

            WHEN r_score <= 2
             AND m_score <= 3
                THEN 'Dormant One-Time'

            ELSE 'Standard One-Time'
        END AS one_time_segment

    FROM rfm_scoring

    WHERE frequency = 1
)

-- STEP 7: Summarize one-time customer segments
SELECT
    one_time_segment,

    COUNT(*) AS total_customers,

    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage,

    ROUND(SUM(monetary), 2) AS total_revenue,

    ROUND(AVG(monetary), 2) AS avg_revenue_per_customer,

    ROUND(AVG(recency), 2) AS avg_recency_days

FROM one_time_segments

GROUP BY one_time_segment

ORDER BY total_revenue DESC;
