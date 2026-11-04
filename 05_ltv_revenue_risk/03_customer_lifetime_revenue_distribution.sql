
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 6: Customer Lifetime Value & Revenue Risk
-- STEP 34: Customer Lifetime Revenue Distribution
-- PURPOSE:
-- Divide customers into four revenue quartiles and
-- analyse their revenue contribution.
-- =====================================================

-- STEP 1: Calculate lifetime revenue for each customer
WITH customer_lifetime_revenue AS (

    SELECT
        c.customer_unique_id,

        SUM(oi.price) AS lifetime_revenue

    FROM olist.customers c

    INNER JOIN olist.orders o
        ON c.customer_id = o.customer_id

    INNER JOIN olist.order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

-- STEP 2: Calculate revenue quartile thresholds
revenue_cutoffs AS (

    SELECT
        PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY lifetime_revenue) AS q1_cutoff,

        PERCENTILE_CONT(0.50)
            WITHIN GROUP (ORDER BY lifetime_revenue) AS q2_cutoff,

        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY lifetime_revenue) AS q3_cutoff

    FROM customer_lifetime_revenue
),

-- STEP 3: Assign each customer to a revenue quartile
customer_revenue_segments AS (

    SELECT
        clr.customer_unique_id,
        clr.lifetime_revenue,

        CASE
            WHEN clr.lifetime_revenue <= rc.q1_cutoff
                THEN 'Q1 - Lowest Revenue'

            WHEN clr.lifetime_revenue <= rc.q2_cutoff
                THEN 'Q2 - Lower-Mid Revenue'

            WHEN clr.lifetime_revenue <= rc.q3_cutoff
                THEN 'Q3 - Upper-Mid Revenue'

            ELSE 'Q4 - Highest Revenue'
        END AS revenue_quartile

    FROM customer_lifetime_revenue clr
    CROSS JOIN revenue_cutoffs rc
),

-- STEP 4: Calculate total customer revenue
overall_revenue AS (

    SELECT
        SUM(lifetime_revenue) AS total_revenue
    FROM customer_revenue_segments
),

-- STEP 5: Summarize revenue by quartile
quartile_summary AS (

    SELECT
        revenue_quartile,

        COUNT(*) AS total_customers,

        SUM(lifetime_revenue) AS quartile_revenue,

        AVG(lifetime_revenue) AS avg_customer_revenue,

        MIN(lifetime_revenue) AS minimum_customer_revenue,

        MAX(lifetime_revenue) AS maximum_customer_revenue

    FROM customer_revenue_segments

    GROUP BY revenue_quartile
)

-- STEP 6: Display customer revenue distribution
SELECT
    qs.revenue_quartile,

    qs.total_customers,

    ROUND(
        qs.total_customers * 100.0 /
        SUM(qs.total_customers) OVER (),
        2
    ) AS customer_percentage,

    ROUND(qs.quartile_revenue, 2) AS total_revenue,

    ROUND(
        qs.quartile_revenue * 100.0 / orv.total_revenue,
        2
    ) AS revenue_contribution_pct,

    ROUND(qs.avg_customer_revenue, 2)
        AS avg_customer_revenue,

    ROUND(qs.minimum_customer_revenue, 2)
        AS minimum_customer_revenue,

    ROUND(qs.maximum_customer_revenue, 2)
        AS maximum_customer_revenue

FROM quartile_summary qs

CROSS JOIN overall_revenue orv

ORDER BY qs.revenue_quartile;
