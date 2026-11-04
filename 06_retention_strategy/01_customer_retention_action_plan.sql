-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 6: Retention Strategy & Business Recommendations
-- STEP 38A: Customer Retention Action Plan
--
-- PURPOSE:
-- Connect customer retention priorities with proposed
-- business actions and measurable success indicators.
-- =====================================================

-- SECTION 1: Identify the dataset snapshot date.
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

-- SECTION 3: Calculate inactivity and revenue quartiles.
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

-- SECTION 4: Assign retention priority.
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
),

-- SECTION 5: Attach a proposed business action
-- and a measurable KPI to each priority group.
retention_actions AS (
    SELECT
        *,

                CASE retention_priority
            WHEN 'Critical Priority'
                THEN 'Reactivation Rate'

            WHEN 'High Priority'
                THEN 'Repeat Purchase Rate'

            WHEN 'Medium Priority'
                THEN 'Purchase Conversion Rate'

            WHEN 'Monitor High-Value'
                THEN 'Repeat Purchase Rate'

            WHEN 'Low Value - Long Inactive'
                THEN 'Reactivation Rate'

            ELSE 'Active Customer Rate'
        END AS success_metric

    FROM customer_priority
)

-- SECTION 6: Summarise the recommended action plan.
SELECT
    retention_priority,
    recommended_action,
    success_metric,

    COUNT(*) AS target_customers,

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
        AVG(inactivity_days),
        2
    ) AS avg_inactivity_days

FROM retention_actions

GROUP BY
    retention_priority,
    recommended_action,
    success_metric

ORDER BY
    CASE retention_priority
        WHEN 'Critical Priority' THEN 1
        WHEN 'High Priority' THEN 2
        WHEN 'Medium Priority' THEN 3
        WHEN 'Monitor High-Value' THEN 4
        WHEN 'Low Value - Long Inactive' THEN 5
        ELSE 6
    END;