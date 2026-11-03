
-- Project: Customer Churn & Retention Intelligence
-- Purpose: Validate imported orders data

SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS null_customer_ids,
    COUNT(*) FILTER (
        WHERE order_purchase_timestamp IS NULL
    ) AS null_purchase_dates,
    MIN(order_purchase_timestamp) AS first_order_date,
    MAX(order_purchase_timestamp) AS last_order_date
FROM olist.orders;

-- Verify customer relationships

SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE c.customer_id IS NULL
    ) AS unmatched_customers
FROM olist.orders o
LEFT JOIN olist.customers c
    ON o.customer_id = c.customer_id;
