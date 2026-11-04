
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 6: Customer Lifetime Value & Revenue Risk
-- STEP 33: Customer Lifetime Revenue Analysis
-- PURPOSE:
-- Calculate lifetime revenue and purchase history
-- for every unique customer.
-- =====================================================

-- STEP 1: Aggregate delivered order data at customer level
WITH customer_lifetime_revenue AS (

    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS total_delivered_orders,

        MIN(o.order_purchase_timestamp)::DATE
            AS first_purchase_date,

        MAX(o.order_purchase_timestamp)::DATE
            AS last_purchase_date,

        SUM(oi.price) AS lifetime_revenue

    FROM olist.customers c

    INNER JOIN olist.orders o
        ON c.customer_id = o.customer_id

    INNER JOIN olist.order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
)

-- STEP 2: Display customer lifetime revenue metrics
SELECT
    customer_unique_id,

    total_delivered_orders,

    first_purchase_date,

    last_purchase_date,

    ROUND(lifetime_revenue, 2) AS lifetime_revenue,

    ROUND(
        lifetime_revenue / total_delivered_orders,
        2
    ) AS avg_revenue_per_order,

    last_purchase_date - first_purchase_date
        AS customer_lifetime_days

FROM customer_lifetime_revenue

ORDER BY lifetime_revenue DESC;

-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 6: Customer Lifetime Value & Revenue Risk
-- STEP 33A: Customer Lifetime Revenue Validation
-- PURPOSE:
-- Validate customer count, delivered orders and total
-- lifetime revenue against previously verified metrics.
-- =====================================================

-- STEP 1: Aggregate delivered revenue at customer level
WITH customer_lifetime_revenue AS (

    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS total_delivered_orders,

        SUM(oi.price) AS lifetime_revenue

    FROM olist.customers c

    INNER JOIN olist.orders o
        ON c.customer_id = o.customer_id

    INNER JOIN olist.order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
)

-- STEP 2: Validate overall customer lifetime metrics
SELECT
    COUNT(*) AS total_customers,

    SUM(total_delivered_orders) AS total_delivered_orders,

    ROUND(SUM(lifetime_revenue), 2) AS total_lifetime_revenue,

    ROUND(AVG(lifetime_revenue), 2) AS avg_lifetime_revenue_per_customer,

    ROUND(MIN(lifetime_revenue), 2) AS minimum_customer_revenue,

    ROUND(MAX(lifetime_revenue), 2) AS maximum_customer_revenue

FROM customer_lifetime_revenue;
