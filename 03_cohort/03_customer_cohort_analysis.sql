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