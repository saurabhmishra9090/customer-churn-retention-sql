
-- Project: Customer Churn & Retention Intelligence
-- Purpose: Validate imported customer data

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_real_customers,
    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS null_customer_ids,
    COUNT(*) FILTER (
        WHERE customer_unique_id IS NULL
    ) AS null_unique_ids
FROM olist.customers;
