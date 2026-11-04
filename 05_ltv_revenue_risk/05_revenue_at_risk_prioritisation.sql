-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 5: Lifetime Value & Revenue Risk
-- STEP 37A: Inactivity x Customer Lifetime Value
-- PURPOSE:
-- Identify high-value customers across inactivity
-- segments and prioritise retention opportunities.
-- =====================================================

-- SECTION 1: Define the dataset snapshot date.
WITH snapshot AS (
    SELECT
        MAX(order_purchase_timestamp)::DATE AS snapshot_date
    FROM olist.orders
),

-- SECTION 2: Calculate each customer's delivered
-- order frequency, lifetime revenue and last purchase.
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

-- SECTION 3: Calculate inactivity and rank customers
-- into four lifetime-revenue quartiles.
customer_scoring AS (
    SELECT
        cm.customer_unique_id,
        cm.delivered_orders,
        cm.lifetime_revenue,
        cm.last_purchase_date,
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

-- SECTION 4: Assign inactivity and value segments.
customer_segments AS (
    SELECT
        *,

        CASE
            WHEN inactivity_days <= 90
                THEN 'Recently Active'
            WHEN inactivity_days <= 180
                THEN 'Cooling'
            WHEN inactivity_days <= 365
                THEN 'Inactive'
            ELSE 'Long Inactive'
        END AS inactivity_segment,

        CASE
            WHEN revenue_quartile = 4
                THEN 'High Value'
            WHEN revenue_quartile = 3
                THEN 'Upper-Mid Value'
            WHEN revenue_quartile = 2
                THEN 'Lower-Mid Value'
            ELSE 'Low Value'
        END AS value_segment

    FROM customer_scoring
)

-- SECTION 5: Summarise historical revenue exposure
-- across inactivity and customer value segments.
SELECT
    inactivity_segment,
    value_segment,

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

FROM customer_segments
GROUP BY
    inactivity_segment,
    value_segment

ORDER BY
    CASE inactivity_segment
        WHEN 'Long Inactive' THEN 1
        WHEN 'Inactive' THEN 2
        WHEN 'Cooling' THEN 3
        ELSE 4
    END,
    CASE value_segment
        WHEN 'High Value' THEN 1
        WHEN 'Upper-Mid Value' THEN 2
        WHEN 'Lower-Mid Value' THEN 3
        ELSE 4
    END;