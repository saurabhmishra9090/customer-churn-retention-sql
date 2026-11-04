-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 7: Executive Business Recommendations
-- STEP 39A: Executive KPI Summary
--
-- PURPOSE:
-- Consolidate the major customer and revenue metrics
-- into one executive-level summary.
--
-- SCOPE:
-- Delivered orders and product revenue only.
-- Snapshot date: Latest purchase date in the dataset.
-- =====================================================

-- SECTION 1: Identify the dataset snapshot date.
WITH snapshot AS (
    SELECT
        MAX(order_purchase_timestamp)::DATE AS snapshot_date
    FROM olist.orders
),

-- SECTION 2: Calculate delivered-order metrics
-- for each real customer.
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

-- SECTION 3: Calculate customer inactivity
-- and revenue quartiles.
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

-- SECTION 4: Aggregate executive-level metrics.
executive_metrics AS (
    SELECT
        COUNT(*) AS total_customers,

        SUM(delivered_orders) AS total_delivered_orders,

        ROUND(SUM(lifetime_revenue), 2)
            AS total_historical_revenue,

        ROUND(AVG(lifetime_revenue), 2)
            AS avg_lifetime_revenue_per_customer,

        COUNT(*) FILTER (
            WHERE inactivity_days > 180
        ) AS inactive_customers,

        ROUND(
            SUM(lifetime_revenue) FILTER (
                WHERE inactivity_days > 180
            ),
            2
        ) AS inactive_customer_revenue,

        COUNT(*) FILTER (
            WHERE revenue_quartile = 4
              AND inactivity_days > 90
        ) AS high_value_inactive_customers,

        ROUND(
            SUM(lifetime_revenue) FILTER (
                WHERE revenue_quartile = 4
                  AND inactivity_days > 90
            ),
            2
        ) AS high_value_inactive_revenue,

        ROUND(
            100.0 * SUM(lifetime_revenue) FILTER (
                WHERE revenue_quartile = 4
            ) / SUM(lifetime_revenue),
            2
        ) AS top_quartile_revenue_contribution_pct

    FROM customer_scoring
)

-- SECTION 5: Display the executive KPI summary.
SELECT
    s.snapshot_date,

    e.total_customers,
    e.total_delivered_orders,
    e.total_historical_revenue,
    e.avg_lifetime_revenue_per_customer,

    e.inactive_customers,

-- Calculate inactive revenue contribution.
ROUND(
    100.0 * e.inactive_customer_revenue
    / NULLIF(e.total_historical_revenue, 0),
    2
) AS inactive_revenue_contribution_pct,

    e.inactive_customer_revenue,

   -- Calculate inactive revenue contribution.
ROUND(
    100.0 * e.inactive_customer_revenue
    / NULLIF(e.total_historical_revenue, 0),
    2
) AS inactive_revenue_contribution_pct,
    e.high_value_inactive_customers,
    e.high_value_inactive_revenue,

   -- Calculate high-value inactive revenue contribution.
ROUND(
    100.0 * e.high_value_inactive_revenue
    / NULLIF(e.total_historical_revenue, 0),
    2
) AS high_value_inactive_revenue_pct,

    e.top_quartile_revenue_contribution_pct

FROM executive_metrics e
CROSS JOIN snapshot s;