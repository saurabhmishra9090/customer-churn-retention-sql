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
