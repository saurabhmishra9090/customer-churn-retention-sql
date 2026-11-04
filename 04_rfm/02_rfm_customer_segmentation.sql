
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 5: RFM Customer Segmentation
-- STEP 28: Customer Segment Classification
-- PURPOSE:
-- Classify customers into actionable business segments
-- using their validated RFM scores.
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

-- STEP 5: Assign validated RFM scores
rfm_scoring AS (

    SELECT
        rm.customer_unique_id,
        rm.recency,
        rm.frequency,
        rm.monetary,

        -- Recent purchases receive higher scores
        CASE
            WHEN rm.recency <= rc.r_p20 THEN 5
            WHEN rm.recency <= rc.r_p40 THEN 4
            WHEN rm.recency <= rc.r_p60 THEN 3
            WHEN rm.recency <= rc.r_p80 THEN 2
            ELSE 1
        END AS r_score,

        -- Frequency uses project-specific business rules
        CASE
            WHEN rm.frequency = 1 THEN 1
            WHEN rm.frequency = 2 THEN 2
            WHEN rm.frequency BETWEEN 3 AND 4 THEN 3
            WHEN rm.frequency BETWEEN 5 AND 6 THEN 4
            ELSE 5
        END AS f_score,

        -- Higher spending receives higher scores
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

-- STEP 6: Assign business segments
customer_segments AS (

    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,

        CONCAT(r_score, f_score, m_score) AS rfm_score,

        CASE
            WHEN r_score >= 4
             AND f_score >= 4
             AND m_score >= 4
                THEN 'Champions'

            WHEN r_score >= 3
             AND f_score >= 4
                THEN 'Loyal Customers'

            WHEN r_score >= 4
             AND f_score BETWEEN 2 AND 3
                THEN 'Potential Loyalists'

            WHEN r_score <= 2
             AND f_score >= 3
                THEN 'At Risk'

            WHEN r_score <= 2
             AND f_score <= 2
                THEN 'Hibernating'

            ELSE 'Other Customers'
        END AS customer_segment

    FROM rfm_scoring
)

-- STEP 7: Display customer-level segmentation
SELECT
    customer_unique_id,
    recency,
    frequency,
    ROUND(monetary, 2) AS monetary,
    r_score,
    f_score,
    m_score,
    rfm_score,
    customer_segment

FROM customer_segments

ORDER BY
    CASE customer_segment
        WHEN 'Champions' THEN 1
        WHEN 'Loyal Customers' THEN 2
        WHEN 'Potential Loyalists' THEN 3
        WHEN 'At Risk' THEN 4
        WHEN 'Hibernating' THEN 5
        ELSE 6
    END,
    r_score DESC,
    f_score DESC,
    m_score DESC;

-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 5: RFM Customer Segmentation
-- STEP 28A: Segment Distribution and Revenue Analysis
-- PURPOSE:
-- Calculate customer count, revenue contribution
-- and average revenue for every RFM segment.
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

-- STEP 4: Calculate scoring cutoffs
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

-- STEP 6: Classify customers into business segments
customer_segments AS (

    SELECT
        customer_unique_id,
        frequency,
        monetary,

        CASE
            WHEN r_score >= 4
             AND f_score >= 4
             AND m_score >= 4
                THEN 'Champions'

            WHEN r_score >= 3
             AND f_score >= 4
                THEN 'Loyal Customers'

            WHEN r_score >= 4
             AND f_score BETWEEN 2 AND 3
                THEN 'Potential Loyalists'

            WHEN r_score <= 2
             AND f_score >= 3
                THEN 'At Risk'

            WHEN r_score <= 2
             AND f_score <= 2
                THEN 'Hibernating'

            ELSE 'Other Customers'
        END AS customer_segment

    FROM rfm_scoring
),

-- STEP 7: Calculate overall revenue
total_revenue AS (

    SELECT SUM(monetary) AS overall_revenue
    FROM customer_segments
),

-- STEP 8: Summarize each customer segment
segment_summary AS (

    SELECT
        customer_segment,
        COUNT(*) AS total_customers,
        SUM(frequency) AS total_orders,
        SUM(monetary) AS total_revenue,
        AVG(monetary) AS avg_revenue_per_customer

    FROM customer_segments

    GROUP BY customer_segment
)

-- STEP 9: Display segment-level business metrics
SELECT
    ss.customer_segment,
    ss.total_customers,
    ss.total_orders,

    ROUND(ss.total_revenue, 2) AS total_revenue,

    ROUND(
        ss.total_revenue * 100.0 / tr.overall_revenue,
        2
    ) AS revenue_contribution_pct,

    ROUND(ss.avg_revenue_per_customer, 2)
        AS avg_revenue_per_customer

FROM segment_summary ss

CROSS JOIN total_revenue tr

ORDER BY ss.total_revenue DESC;
