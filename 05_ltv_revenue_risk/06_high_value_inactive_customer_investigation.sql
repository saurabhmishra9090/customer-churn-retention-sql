-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 5: Lifetime Value & Revenue Risk
-- STEP 37B: High-Value Inactive Customer Investigation
--
-- PURPOSE:
-- Identify individual high-value customers who have
-- been inactive for more than 180 days.
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
        MIN(o.order_purchase_timestamp)::DATE AS first_purchase_date,
        MAX(o.order_purchase_timestamp)::DATE AS last_purchase_date
    FROM olist.customers c
    JOIN olist.orders o
        ON c.customer_id = o.customer_id
    JOIN olist.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

-- SECTION 3: Calculate inactivity and lifetime
-- revenue quartiles across the full customer base.
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
)

-- SECTION 4: Return individual high-value customers
-- who have been inactive for more than 180 days.
SELECT
    customer_unique_id,
    delivered_orders,
    first_purchase_date,
    last_purchase_date,
    inactivity_days,

    ROUND(lifetime_revenue, 2) AS lifetime_revenue,

    ROUND(
        lifetime_revenue / delivered_orders,
        2
    ) AS avg_revenue_per_order,

    CASE
        WHEN inactivity_days > 365
            THEN 'Long Inactive'
        ELSE 'Inactive'
    END AS inactivity_segment

FROM customer_scoring

WHERE revenue_quartile = 4
  AND inactivity_days > 180

ORDER BY
    lifetime_revenue DESC,
    inactivity_days DESC

LIMIT 100;