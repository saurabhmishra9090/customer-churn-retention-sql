-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 6: Retention Strategy & Business Recommendations
-- STEP 38C: Treatment Group vs Control Group
--
-- PURPOSE:
-- Create a proposed 50/50 experiment allocation
-- within each customer retention priority segment.
--
-- IMPORTANT:
-- This is a planning simulation, not an executed
-- marketing experiment or actual campaign assignment.
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

-- SECTION 4: Assign retention priority groups.
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

-- SECTION 5: Divide customers into two balanced groups
-- separately within each retention priority segment.
experiment_assignment AS (
    SELECT
        *,

        NTILE(2) OVER (
            PARTITION BY retention_priority
            ORDER BY MD5(customer_unique_id)
        ) AS experiment_group_number

    FROM customer_priority
),

-- SECTION 6: Label the proposed experiment groups.
labelled_groups AS (
    SELECT
        *,

        CASE
            WHEN experiment_group_number = 1
                THEN 'Treatment Group'
            ELSE 'Control Group'
        END AS experiment_group

    FROM experiment_assignment
)

-- SECTION 7: Summarise the proposed experiment design.
SELECT
    retention_priority,
    experiment_group,

    COUNT(*) AS allocated_customers,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (
            PARTITION BY retention_priority
        ),
        2
    ) AS segment_allocation_pct,

    ROUND(
        SUM(lifetime_revenue),
        2
    ) AS historical_revenue,

    ROUND(
        AVG(lifetime_revenue),
        2
    ) AS avg_revenue_per_customer,

    ROUND(
        AVG(inactivity_days),
        2
    ) AS avg_inactivity_days,

    'Planning Only - Campaign Not Executed'
        AS experiment_status

FROM labelled_groups

GROUP BY
    retention_priority,
    experiment_group

ORDER BY
    CASE retention_priority
        WHEN 'Critical Priority' THEN 1
        WHEN 'High Priority' THEN 2
        WHEN 'Medium Priority' THEN 3
        WHEN 'Monitor High-Value' THEN 4
        WHEN 'Low Value - Long Inactive' THEN 5
        ELSE 6
    END,

    experiment_group;