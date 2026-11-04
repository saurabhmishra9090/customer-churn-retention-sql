
-- ============================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 2: Customer Purchase Behaviour Analysis
-- FILE: 01_customer_purchase_behavior.sql
-- DATABASE: churn_project
-- SCHEMA: olist
-- ============================================================


-- ============================================================
-- ANALYSIS 1: ONE-TIME VS REPEAT CUSTOMER ANALYSIS
-- PURPOSE: Identify customers who purchased once or multiple
--          times and calculate the repeat customer percentage.
-- ============================================================

SELECT
    COUNT(*) AS total_customers,

    -- Customers who placed exactly one order
    COUNT(*) FILTER (
        WHERE order_count = 1
    ) AS one_time_customers,

    -- Customers who placed more than one order
    COUNT(*) FILTER (
        WHERE order_count > 1
    ) AS repeat_customers,

    -- Percentage of customers who purchased repeatedly
    ROUND(
        COUNT(*) FILTER (
            WHERE order_count > 1
        ) * 100.0 / COUNT(*),
        2
    ) AS repeat_customer_percentage

FROM (
    -- Calculate total orders for each real customer
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS order_count

    FROM olist.customers c

    JOIN olist.orders o
        ON c.customer_id = o.customer_id

    GROUP BY c.customer_unique_id
) customer_orders;


-- ============================================================
-- ANALYSIS 2: CUSTOMER ORDER FREQUENCY DISTRIBUTION
-- PURPOSE: Find how many customers placed 1, 2, 3 or more
--          orders and calculate their percentage.
-- ============================================================

SELECT
    order_count,
    COUNT(*) AS total_customers,

    -- Percentage of customers in each order-frequency group
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage

FROM (
    -- Calculate orders placed by each real customer
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS order_count

    FROM olist.customers c

    JOIN olist.orders o
        ON c.customer_id = o.customer_id

    GROUP BY c.customer_unique_id
) customer_frequency

GROUP BY order_count
ORDER BY order_count;


-- ============================================================
-- ANALYSIS 3: REPEAT PURCHASE TIMING ANALYSIS
-- PURPOSE: Calculate the time gap between the first and
--          second purchase of each repeat customer.
-- ============================================================

WITH customer_purchase_dates AS (

    -- Number purchases separately for each real customer
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp,

        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ) AS purchase_number

    FROM olist.customers c

    JOIN olist.orders o
        ON c.customer_id = o.customer_id
),

repeat_purchase_gap AS (

    -- Match each customer's first and second purchase
    SELECT
        first_purchase.customer_unique_id,

        first_purchase.order_purchase_timestamp
            AS first_order_date,

        second_purchase.order_purchase_timestamp
            AS second_order_date,

        -- Convert the time difference into days
        EXTRACT(
            EPOCH FROM (
                second_purchase.order_purchase_timestamp
                - first_purchase.order_purchase_timestamp
            )
        ) / 86400.0 AS days_between_orders

    FROM customer_purchase_dates first_purchase

    JOIN customer_purchase_dates second_purchase
        ON first_purchase.customer_unique_id =
           second_purchase.customer_unique_id

    WHERE first_purchase.purchase_number = 1
      AND second_purchase.purchase_number = 2
)

-- Summarize the repeat purchase time gap
SELECT
    COUNT(*) AS repeat_customers,

    ROUND(
        AVG(days_between_orders)::NUMERIC,
        2
    ) AS avg_days_between_orders,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY days_between_orders)::NUMERIC,
        2
    ) AS median_days_between_orders,

    ROUND(
        MIN(days_between_orders)::NUMERIC,
        2
    ) AS minimum_days,

    ROUND(
        MAX(days_between_orders)::NUMERIC,
        2
    ) AS maximum_days

FROM repeat_purchase_gap;


-- ============================================================
-- ANALYSIS 4: REPEAT PURCHASE GAP DISTRIBUTION
-- PURPOSE: Segment repeat customers according to the number
--          of days taken to place their second order.
-- ============================================================

WITH customer_purchase_dates AS (

    -- Number every purchase for each real customer
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp,

        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ) AS purchase_number

    FROM olist.customers c

    JOIN olist.orders o
        ON c.customer_id = o.customer_id
),

repeat_purchase_gap AS (

    -- Calculate days between first and second purchases
    SELECT
        first_purchase.customer_unique_id,

        EXTRACT(
            EPOCH FROM (
                second_purchase.order_purchase_timestamp
                - first_purchase.order_purchase_timestamp
            )
        ) / 86400.0 AS days_between_orders

    FROM customer_purchase_dates first_purchase

    JOIN customer_purchase_dates second_purchase
        ON first_purchase.customer_unique_id =
           second_purchase.customer_unique_id

    WHERE first_purchase.purchase_number = 1
      AND second_purchase.purchase_number = 2
),

purchase_gap_segments AS (

    -- Assign customers to purchase-gap segments
    SELECT
        customer_unique_id,
        days_between_orders,

        CASE
            WHEN days_between_orders <= 30
                THEN '0-30 days'
            WHEN days_between_orders <= 60
                THEN '31-60 days'
            WHEN days_between_orders <= 90
                THEN '61-90 days'
            ELSE 'Above 90 days'
        END AS purchase_gap_segment

    FROM repeat_purchase_gap
)

-- Count customers in each purchase-gap segment
SELECT
    purchase_gap_segment,
    COUNT(*) AS total_customers,

    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM purchase_gap_segments

GROUP BY purchase_gap_segment

ORDER BY
    CASE purchase_gap_segment
        WHEN '0-30 days' THEN 1
        WHEN '31-60 days' THEN 2
        WHEN '61-90 days' THEN 3
        ELSE 4
    END;
