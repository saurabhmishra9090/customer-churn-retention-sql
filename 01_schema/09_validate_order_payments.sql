
-- Project: Customer Churn & Retention Intelligence
-- Purpose: Validate imported order payment data

-- 1. Overall data quality and payment totals
SELECT
    COUNT(*) AS total_payments,
    COUNT(DISTINCT (order_id, payment_sequential))
        AS unique_payment_records,
    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS null_order_ids,
    COUNT(*) FILTER (
        WHERE payment_value <= 0
    ) AS invalid_payment_values,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM olist.order_payments;


-- 2. Payment method distribution
SELECT
    payment_type,
    COUNT(*) AS payment_records,
    COUNT(*) FILTER (
        WHERE payment_value <= 0
    ) AS invalid_records,
    ROUND(SUM(payment_value), 2) AS total_payment
FROM olist.order_payments
GROUP BY payment_type
ORDER BY payment_records DESC;


-- 3. Verify payment-to-order relationship
SELECT
    COUNT(*) AS total_payments,
    COUNT(*) FILTER (
        WHERE o.order_id IS NULL
    ) AS unmatched_orders
FROM olist.order_payments p
LEFT JOIN olist.orders o
    ON p.order_id = o.order_id;
