
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 2: Data Cleaning & Quality
-- STEP 9: Cleaned Views Cross-Validation
--
-- PURPOSE:
-- Compare original source tables with cleaned views.
-- Verify record counts, uniqueness and anomaly flags.
--
-- IMPORTANT:
-- This is a read-only validation script.
-- No source records are modified or deleted.
-- =====================================================

-- SECTION 1: Validate record counts and uniqueness.
WITH validation_results AS (

    SELECT
        'Orders' AS table_name,

        (SELECT COUNT(*)
         FROM olist.orders) AS original_records,

        (SELECT COUNT(*)
         FROM olist.vw_orders_cleaned) AS cleaned_records,

        (SELECT COUNT(DISTINCT order_id)
         FROM olist.vw_orders_cleaned) AS unique_records

    UNION ALL

    SELECT
        'Payments',

        (SELECT COUNT(*)
         FROM olist.order_payments),

        (SELECT COUNT(*)
         FROM olist.vw_payments_cleaned),

        (SELECT COUNT(DISTINCT (order_id, payment_sequential))
         FROM olist.vw_payments_cleaned)

    UNION ALL

    SELECT
        'Products',

        (SELECT COUNT(*)
         FROM olist.products),

        (SELECT COUNT(*)
         FROM olist.vw_products_cleaned),

        (SELECT COUNT(DISTINCT product_id)
         FROM olist.vw_products_cleaned)

    UNION ALL

    SELECT
        'Customers',

        (SELECT COUNT(*)
         FROM olist.customers),

        (SELECT COUNT(*)
         FROM olist.vw_customers_cleaned),

        (SELECT COUNT(DISTINCT customer_id)
         FROM olist.vw_customers_cleaned)
)

-- SECTION 2: Display record preservation results.
SELECT
    table_name,
    original_records,
    cleaned_records,
    unique_records,

    cleaned_records - original_records
        AS record_count_difference,

    CASE
        WHEN original_records = cleaned_records
         AND cleaned_records = unique_records
            THEN 'PASS'

        ELSE 'REVIEW REQUIRED'
    END AS validation_status

FROM validation_results

ORDER BY
    CASE table_name
        WHEN 'Orders' THEN 1
        WHEN 'Payments' THEN 2
        WHEN 'Products' THEN 3
        WHEN 'Customers' THEN 4
    END;


-- SECTION 3: Validate known order anomaly flags.
SELECT
    COUNT(*) FILTER (
        WHERE carrier_before_approval_flag
    ) AS carrier_before_approval,

    COUNT(*) FILTER (
        WHERE delivery_before_carrier_flag
    ) AS delivery_before_carrier,

    COUNT(*) FILTER (
        WHERE delivery_before_purchase_flag
    ) AS delivery_before_purchase,

    COUNT(*) FILTER (
        WHERE delivery_performance_status = 'Late Delivery'
    ) AS late_deliveries

FROM olist.vw_orders_cleaned;


-- SECTION 4: Validate known payment anomaly flags.
SELECT
    COUNT(*) FILTER (
        WHERE non_positive_payment_flag
    ) AS non_positive_payments,

    COUNT(*) FILTER (
        WHERE invalid_installment_flag
    ) AS invalid_installments,

    COUNT(*) FILTER (
        WHERE unmatched_order_flag
    ) AS unmatched_payment_orders

FROM olist.vw_payments_cleaned;


-- SECTION 5: Validate known product anomaly flags.
SELECT
    COUNT(*) FILTER (
        WHERE missing_category_flag
    ) AS missing_categories,

    COUNT(*) FILTER (
        WHERE missing_weight_flag
    ) AS missing_weights,

    COUNT(*) FILTER (
        WHERE invalid_weight_flag
    ) AS invalid_weights,

    COUNT(*) FILTER (
        WHERE missing_dimensions_flag
    ) AS missing_dimensions,

    COUNT(*) FILTER (
        WHERE missing_translation_flag
    ) AS missing_translations

FROM olist.vw_products_cleaned;


-- SECTION 6: Validate customer data quality flags.
SELECT
    COUNT(*) FILTER (
        WHERE missing_customer_id_flag
    ) AS missing_customer_ids,

    COUNT(*) FILTER (
        WHERE missing_unique_customer_id_flag
    ) AS missing_unique_customer_ids,

    COUNT(*) FILTER (
        WHERE invalid_zip_code_flag
    ) AS invalid_zip_codes,

    COUNT(*) FILTER (
        WHERE invalid_state_code_flag
    ) AS invalid_state_codes,

    COUNT(*) FILTER (
        WHERE customer_quality_status = 'Requires Review'
    ) AS customers_requiring_review

FROM olist.vw_customers_cleaned;
