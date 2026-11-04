-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 5: Lifetime Value & Revenue Risk
-- STEP 37C: Retention Priority Classification
--
-- PURPOSE:
-- Classify customers using historical revenue value
-- and inactivity duration.
-- =====================================================

-- SECTION 1: Find the dataset snapshot date.
WITH snapshot AS (
    SELECT
        MAX(order_purchase_timestamp)::DATE AS snapshot_date
    FROM olist.orders
),

-- SECTION 2: Calculate delivered-order metrics
-- for every real customer.
customer_metrics AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS delivered_orders,
        SUM(oi.price) AS lifetime_revenue,
        MAX(o.order_purchase_timestamp)::DATE AS last_purchase_date
    FROM olist.customers c
    JOIN olist.orders o
        ON c.customer_id = o.customer_id
    JOIN olist.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

-- SECTION 3: Calculate inactivity and customer
-- lifetime revenue quartiles.
customer_scoring AS (
    SELECT
        cm.*,
        s.snapshot_date,

        s.snapshot_date - cm.last_purchase_date
            AS inactivity_days,

        NTILE(4) OVER (
            ORDER BY cm.lifetime_revenue,
                     cm.customer_unique_id
        ) AS revenue_quartile

    FROM customer_metrics cm
    CROSS JOIN snapshot s
),

-- SECTION 4: Assign retention priority levels.
customer_priority AS (
    SELECT
        *,

        CASE
            WHEN revenue_quartile = 4
                 AND inactivity_days > 365
                THEN 'Critical Priority'

            WHEN revenue_quartile = 4
                 AND inactivity_days > 180
                THEN 'High Priority'

            WHEN revenue_quartile = 4
                 AND inactivity_days > 90
                THEN 'Medium Priority'

            WHEN revenue_quartile = 4
                THEN 'Monitor High-Value'

            WHEN inactivity_days > 365
                THEN 'Low Value - Long Inactive'

            ELSE 'Standard Monitoring'
        END AS retention_priority

    FROM customer_scoring
)

-- SECTION 5: Summarise customers and their
-- historical revenue by retention priority.
SELECT
    retention_priority,

    COUNT(*) AS customers,

    SUM(delivered_orders) AS delivered_orders,

    ROUND(
        SUM(lifetime_revenue),
        2
    ) AS historical_revenue,

    ROUND(
        100.0 * SUM(lifetime_revenue)
        / SUM(SUM(lifetime_revenue)) OVER (),
        2
    ) AS revenue_contribution_pct,

    ROUND(
        AVG(lifetime_revenue),
        2
    ) AS avg_revenue_per_customer,

    ROUND(
        AVG(inactivity_days),
        2
    ) AS avg_inactivity_days

FROM customer_priority
GROUP BY retention_priority

ORDER BY
    CASE retention_priority
        WHEN 'Critical Priority' THEN 1
        WHEN 'High Priority' THEN 2
        WHEN 'Medium Priority' THEN 3
        WHEN 'Monitor High-Value' THEN 4
        WHEN 'Low Value - Long Inactive' THEN 5
        ELSE 6
    END;