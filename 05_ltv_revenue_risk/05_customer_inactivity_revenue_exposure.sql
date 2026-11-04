
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 6: Customer Lifetime Value & Revenue Risk
-- STEP 36: Customer Inactivity & Revenue Exposure
-- PURPOSE:
-- Measure customer inactivity and historical revenue
-- associated with each inactivity group.
-- =====================================================

-- STEP 1: Calculate customer-level delivered revenue
WITH customer_metrics AS (

    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS delivered_orders,

        MAX(o.order_purchase_timestamp)::DATE
            AS last_purchase_date,

        SUM(oi.price) AS lifetime_revenue

    FROM olist.customers c

    INNER JOIN olist.orders o
        ON c.customer_id = o.customer_id

    INNER JOIN olist.order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

-- STEP 2: Identify the dataset snapshot date
dataset_snapshot AS (

    SELECT
        MAX(order_purchase_timestamp)::DATE AS snapshot_date
    FROM olist.orders
),

-- STEP 3: Calculate customer inactivity days
customer_inactivity AS (

    SELECT
        cm.customer_unique_id,

        cm.delivered_orders,

        cm.last_purchase_date,

        ds.snapshot_date - cm.last_purchase_date
            AS inactivity_days,

        cm.lifetime_revenue

    FROM customer_metrics cm
    CROSS JOIN dataset_snapshot ds
),

-- STEP 4: Classify customers by inactivity
inactivity_segments AS (

    SELECT
        customer_unique_id,

        delivered_orders,

        inactivity_days,

        lifetime_revenue,

        CASE
            WHEN inactivity_days <= 90
                THEN 'Recently Active'

            WHEN inactivity_days <= 180
                THEN 'Cooling'

            WHEN inactivity_days <= 365
                THEN 'Inactive'

            ELSE 'Long Inactive'
        END AS inactivity_segment

    FROM customer_inactivity
),

-- STEP 5: Calculate total historical revenue
overall_revenue AS (

    SELECT
        SUM(lifetime_revenue) AS total_revenue
    FROM inactivity_segments
),

-- STEP 6: Summarize customer inactivity groups
inactivity_summary AS (

    SELECT
        inactivity_segment,

        COUNT(*) AS total_customers,

        SUM(delivered_orders) AS total_delivered_orders,

        SUM(lifetime_revenue) AS historical_revenue,

        AVG(lifetime_revenue) AS avg_customer_revenue,

        AVG(inactivity_days) AS avg_inactivity_days

    FROM inactivity_segments

    GROUP BY inactivity_segment
)

-- STEP 7: Display revenue exposure by inactivity group
SELECT
    s.inactivity_segment,

    s.total_customers,

    ROUND(
        s.total_customers * 100.0 /
        SUM(s.total_customers) OVER (),
        2
    ) AS customer_percentage,

    s.total_delivered_orders,

    ROUND(s.historical_revenue, 2)
        AS historical_revenue,

    ROUND(
        s.historical_revenue * 100.0 / r.total_revenue,
        2
    ) AS revenue_contribution_pct,

    ROUND(s.avg_customer_revenue, 2)
        AS avg_customer_revenue,

    ROUND(s.avg_inactivity_days, 2)
        AS avg_inactivity_days

FROM inactivity_summary s

CROSS JOIN overall_revenue r

ORDER BY
    CASE s.inactivity_segment
        WHEN 'Recently Active' THEN 1
        WHEN 'Cooling' THEN 2
        WHEN 'Inactive' THEN 3
        WHEN 'Long Inactive' THEN 4
    END;
