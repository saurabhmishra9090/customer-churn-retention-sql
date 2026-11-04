
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 5: RFM Customer Segmentation
-- STEP 32: Unified Customer Segmentation
-- PURPOSE:
-- Combine one-time and repeat customer classifications
-- into one final customer segmentation framework.
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

-- STEP 3: Calculate Recency, Frequency and Monetary
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

-- STEP 5: Assign validated RFM scores
rfm_scoring AS (

    SELECT
        rm.customer_unique_id,
        rm.recency,
        rm.frequency,
        rm.monetary,

        -- Lower recency means a higher score
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

        -- Higher monetary value means a higher score
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

-- STEP 6: Create unified customer segments
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

            -- One-time customer classification
            WHEN frequency = 1 AND m_score >= 4
                THEN 'High-Value One-Time'

            WHEN frequency = 1
             AND r_score >= 4
             AND m_score <= 3
                THEN 'Recent One-Time'

            WHEN frequency = 1
             AND r_score <= 2
             AND m_score <= 3
                THEN 'Dormant One-Time'

            WHEN frequency = 1
                THEN 'Standard One-Time'

            -- Repeat customer classification
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

            ELSE 'Other Repeat Customers'

        END AS customer_segment

    FROM rfm_scoring
)

-- STEP 7: Display unified customer segmentation
SELECT
    customer_segment,

    COUNT(*) AS total_customers,

    SUM(frequency) AS total_orders,

    ROUND(SUM(monetary), 2) AS total_revenue,

    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage,

    ROUND(
        SUM(monetary) * 100.0 /
        SUM(SUM(monetary)) OVER (),
        2
    ) AS revenue_contribution_pct,

    ROUND(AVG(monetary), 2) AS avg_revenue_per_customer,

    ROUND(AVG(recency), 2) AS avg_recency_days

FROM customer_segments

GROUP BY customer_segment

ORDER BY total_revenue DESC;
