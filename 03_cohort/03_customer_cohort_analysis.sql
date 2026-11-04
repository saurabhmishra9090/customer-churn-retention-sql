-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 4: Cohort Retention Analysis
-- STEP 21: First Purchase Cohort Identification
-- PURPOSE:
-- Identify each customer's first purchase month
-- and classify customers into monthly cohorts.
-- =====================================================

-- STEP 1: Identify the first purchase date per customer
WITH customer_first_purchase AS (

    SELECT
        c.customer_unique_id,

        -- Find the customer's earliest order date
        MIN(o.order_purchase_timestamp)::DATE AS first_purchase_date

    FROM olist.customers c

    INNER JOIN olist.orders o
        ON c.customer_id = o.customer_id

    -- Include all order statuses for cohort assignment
    GROUP BY c.customer_unique_id
),

-- STEP 2: Assign each customer to a monthly cohort
customer_cohorts AS (

    SELECT
        customer_unique_id,
        first_purchase_date,

        -- Convert first purchase date into monthly cohort
        DATE_TRUNC(
            'month',
            first_purchase_date
        )::DATE AS cohort_month

    FROM customer_first_purchase
)

-- STEP 3: Summarize monthly cohort sizes
SELECT
    cohort_month,

    -- Number of unique customers acquired in each month
    COUNT(*) AS cohort_customers

FROM customer_cohorts

GROUP BY cohort_month

ORDER BY cohort_month;

-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 4: Cohort Retention Analysis
-- STEP 22: Corrected Monthly Cohort Retention Matrix
-- PURPOSE:
-- Measure monthly customer retention using delivered
-- purchases consistently for cohort assignment
-- and subsequent customer activity.
-- =====================================================

-- STEP 1: Find each customer's first delivered purchase
WITH customer_first_purchase AS (

    SELECT
        c.customer_unique_id,

        -- Earliest delivered order date for each customer
        MIN(o.order_purchase_timestamp)::DATE AS first_purchase_date

    FROM olist.customers c

    INNER JOIN olist.orders o
        ON c.customer_id = o.customer_id

    -- Only successfully delivered orders
    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

-- STEP 2: Assign each customer to a monthly cohort
customer_cohorts AS (

    SELECT
        customer_unique_id,

        -- First delivered purchase month
        DATE_TRUNC(
            'month',
            first_purchase_date
        )::DATE AS cohort_month

    FROM customer_first_purchase
),

-- STEP 3: Identify monthly delivered purchase activity
delivered_activity AS (

    SELECT DISTINCT
        c.customer_unique_id,

        -- Month of delivered purchase activity
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS activity_month

    FROM olist.customers c

    INNER JOIN olist.orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'
),

-- STEP 4: Connect customer cohorts with activity months
cohort_activity AS (

    SELECT
        cc.customer_unique_id,
        cc.cohort_month,
        da.activity_month,

        -- Calculate months since first delivered purchase
        (
            EXTRACT(YEAR FROM da.activity_month) -
            EXTRACT(YEAR FROM cc.cohort_month)
        ) * 12
        +
        (
            EXTRACT(MONTH FROM da.activity_month) -
            EXTRACT(MONTH FROM cc.cohort_month)
        ) AS cohort_index

    FROM customer_cohorts cc

    INNER JOIN delivered_activity da
        ON cc.customer_unique_id = da.customer_unique_id

    -- Exclude activity before cohort month
    WHERE da.activity_month >= cc.cohort_month
),

-- STEP 5: Calculate active customers in each cohort month
cohort_retention AS (

    SELECT
        cohort_month,
        cohort_index,

        -- Unique customers with delivered activity
        COUNT(DISTINCT customer_unique_id) AS active_customers

    FROM cohort_activity

    GROUP BY cohort_month, cohort_index
),

-- STEP 6: Calculate original cohort sizes
cohort_sizes AS (

    SELECT
        cohort_month,

        -- Total customers acquired in each delivered cohort
        COUNT(*) AS cohort_customers

    FROM customer_cohorts

    GROUP BY cohort_month
)

-- STEP 7: Calculate monthly retention percentages
SELECT
    cr.cohort_month,
    cr.cohort_index,
    cs.cohort_customers,
    cr.active_customers,

    -- Retention percentage for each cohort month
    ROUND(
        cr.active_customers * 100.0 /
        cs.cohort_customers,
        2
    ) AS retention_percentage

FROM cohort_retention cr

INNER JOIN cohort_sizes cs
    ON cr.cohort_month = cs.cohort_month

ORDER BY
    cr.cohort_month,
    cr.cohort_index;
    
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 4: Cohort Retention Analysis
-- STEP 23: Final Cohort Retention Pivot Matrix
-- PURPOSE:
-- Create a complete monthly retention matrix.
-- Show 0% when an observed month has no active customers.
-- Keep future, unobserved months as NULL.
-- =====================================================

-- STEP 1: Find each customer's first delivered purchase
WITH customer_first_purchase AS (

    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp)::DATE AS first_purchase_date

    FROM olist.customers c

    INNER JOIN olist.orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

-- STEP 2: Assign monthly cohorts
customer_cohorts AS (

    SELECT
        customer_unique_id,

        DATE_TRUNC(
            'month',
            first_purchase_date
        )::DATE AS cohort_month

    FROM customer_first_purchase
),

-- STEP 3: Identify delivered activity months
delivered_activity AS (

    SELECT DISTINCT
        c.customer_unique_id,

        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS activity_month

    FROM olist.customers c

    INNER JOIN olist.orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'
),

-- STEP 4: Find the latest observed delivered activity month
dataset_snapshot AS (

    SELECT
        MAX(activity_month) AS snapshot_month
    FROM delivered_activity
),

-- STEP 5: Calculate active customers by cohort month
cohort_activity AS (

    SELECT
        cc.customer_unique_id,
        cc.cohort_month,

        (
            EXTRACT(YEAR FROM da.activity_month) -
            EXTRACT(YEAR FROM cc.cohort_month)
        ) * 12
        +
        (
            EXTRACT(MONTH FROM da.activity_month) -
            EXTRACT(MONTH FROM cc.cohort_month)
        ) AS cohort_index

    FROM customer_cohorts cc

    INNER JOIN delivered_activity da
        ON cc.customer_unique_id = da.customer_unique_id

    WHERE da.activity_month >= cc.cohort_month
),

-- STEP 6: Count active customers in observed months
monthly_activity AS (

    SELECT
        cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_unique_id) AS active_customers

    FROM cohort_activity

    GROUP BY cohort_month, cohort_index
),

-- STEP 7: Calculate original cohort sizes
cohort_sizes AS (

    SELECT
        cohort_month,
        COUNT(*) AS cohort_customers

    FROM customer_cohorts

    GROUP BY cohort_month
),

-- STEP 8: Generate every observable cohort-month combination
complete_cohort_grid AS (

    SELECT
        cs.cohort_month,
        cs.cohort_customers,
        gs.cohort_index

    FROM cohort_sizes cs

    CROSS JOIN dataset_snapshot ds

    CROSS JOIN LATERAL GENERATE_SERIES(
        0,
        (
            EXTRACT(YEAR FROM ds.snapshot_month) -
            EXTRACT(YEAR FROM cs.cohort_month)
        ) * 12
        +
        (
            EXTRACT(MONTH FROM ds.snapshot_month) -
            EXTRACT(MONTH FROM cs.cohort_month)
        )
    ) AS gs(cohort_index)
),

-- STEP 9: Calculate retention, preserving zero-activity months
retention_data AS (

    SELECT
        cg.cohort_month,
        cg.cohort_index,

        COALESCE(ma.active_customers, 0) AS active_customers,

        ROUND(
            COALESCE(ma.active_customers, 0) * 100.0
            / cg.cohort_customers,
            2
        ) AS retention_percentage

    FROM complete_cohort_grid cg

    LEFT JOIN monthly_activity ma
        ON cg.cohort_month = ma.cohort_month
       AND cg.cohort_index = ma.cohort_index
)

-- STEP 10: Pivot retention percentages into columns
SELECT
    cohort_month,

    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 0) AS month_0,

    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 1) AS month_1,

    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 2) AS month_2,

    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 3) AS month_3,

    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 4) AS month_4,

    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 5) AS month_5,

    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 6) AS month_6,

    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 7) AS month_7,

    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 8) AS month_8,

    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 9) AS month_9,

    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 10) AS month_10,

    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 11) AS month_11,

    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 12) AS month_12

FROM retention_data

GROUP BY cohort_month

ORDER BY cohort_month;

-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 4: Cohort Retention Analysis
-- STEP 24: Cohort Retention Summary
-- PURPOSE:
-- Compare customer retention across Month 1, 3, 6
-- and 12 for each monthly acquisition cohort.
-- =====================================================

-- STEP 1: Find each customer's first delivered purchase
WITH customer_first_purchase AS (

    SELECT
        c.customer_unique_id,

        -- Identify the first delivered purchase date
        MIN(o.order_purchase_timestamp)::DATE AS first_purchase_date

    FROM olist.customers c

    INNER JOIN olist.orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

-- STEP 2: Assign customers to monthly cohorts
customer_cohorts AS (

    SELECT
        customer_unique_id,

        DATE_TRUNC(
            'month',
            first_purchase_date
        )::DATE AS cohort_month

    FROM customer_first_purchase
),

-- STEP 3: Identify delivered purchase activity
delivered_activity AS (

    SELECT DISTINCT
        c.customer_unique_id,

        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS activity_month

    FROM olist.customers c

    INNER JOIN olist.orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'
),

-- STEP 4: Calculate customer activity month index
cohort_activity AS (

    SELECT
        cc.customer_unique_id,
        cc.cohort_month,

        (
            EXTRACT(YEAR FROM da.activity_month) -
            EXTRACT(YEAR FROM cc.cohort_month)
        ) * 12
        +
        (
            EXTRACT(MONTH FROM da.activity_month) -
            EXTRACT(MONTH FROM cc.cohort_month)
        ) AS cohort_index

    FROM customer_cohorts cc

    INNER JOIN delivered_activity da
        ON cc.customer_unique_id = da.customer_unique_id

    WHERE da.activity_month >= cc.cohort_month
),

-- STEP 5: Calculate active customers for each cohort month
monthly_retention AS (

    SELECT
        cohort_month,
        cohort_index,

        COUNT(DISTINCT customer_unique_id) AS active_customers

    FROM cohort_activity

    GROUP BY cohort_month, cohort_index
),

-- STEP 6: Calculate original cohort sizes
cohort_sizes AS (

    SELECT
        cohort_month,
        COUNT(*) AS cohort_customers

    FROM customer_cohorts

    GROUP BY cohort_month
),

-- STEP 7: Calculate retention percentages
retention_summary AS (

    SELECT
        cs.cohort_month,
        cs.cohort_customers,
        mr.cohort_index,

        -- Calculate customer retention percentage
        ROUND(
            COALESCE(mr.active_customers, 0) * 100.0
            / cs.cohort_customers,
            2
        ) AS retention_percentage

    FROM cohort_sizes cs

    LEFT JOIN monthly_retention mr
        ON cs.cohort_month = mr.cohort_month
       AND mr.cohort_index IN (0, 1, 3, 6, 12)
)

-- STEP 8: Create business-friendly cohort summary
SELECT
    cohort_month,
    cohort_customers,

    -- Month 1 retention
    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 1) AS month_1_retention,

    -- Month 3 retention
    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 3) AS month_3_retention,

    -- Month 6 retention
    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 6) AS month_6_retention,

    -- Month 12 retention
    MAX(retention_percentage)
        FILTER (WHERE cohort_index = 12) AS month_12_retention

FROM retention_summary

GROUP BY cohort_month, cohort_customers

ORDER BY cohort_month;

