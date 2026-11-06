
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 2: Data Cleaning & Quality
-- STEP 3: Transaction Data Quality Audit
--
-- PURPOSE:
-- Audit payment transactions and order-item records
-- for missing identifiers and invalid financial values.
--
-- IMPORTANT:
-- This is a read-only audit query.
-- No original records are modified or deleted.
-- =====================================================


-- SECTION 1: Audit payment transaction records.
WITH payment_quality AS (

    SELECT
        COUNT(*) AS total_payment_records,

        -- Check missing payment order identifiers.
        COUNT(*) FILTER (
            WHERE p.order_id IS NULL
        ) AS null_order_ids,

        -- Check missing payment methods.
        COUNT(*) FILTER (
            WHERE p.payment_type IS NULL
        ) AS null_payment_types,

        -- Check missing payment amounts.
        COUNT(*) FILTER (
            WHERE p.payment_value IS NULL
        ) AS null_payment_values,

        -- Identify zero or negative payment amounts.
        COUNT(*) FILTER (
            WHERE p.payment_value <= 0
        ) AS non_positive_payment_values,

        -- Identify invalid installment counts.
        COUNT(*) FILTER (
            WHERE p.payment_installments <= 0
        ) AS invalid_installments,

        -- Check unexpected payment methods.
        COUNT(*) FILTER (
            WHERE p.payment_type NOT IN (
                'credit_card',
                'boleto',
                'voucher',
                'debit_card',
                'not_defined'
            )
            OR p.payment_type IS NULL
        ) AS unexpected_payment_types,

        -- Check payment records without matching orders.
        COUNT(*) FILTER (
            WHERE o.order_id IS NULL
        ) AS unmatched_orders

    FROM olist.order_payments p

    LEFT JOIN olist.orders o
        ON p.order_id = o.order_id
),


-- SECTION 2: Audit order-item financial records.
order_item_quality AS (

    SELECT
        COUNT(*) AS total_order_items,

        -- Check missing order identifiers.
        COUNT(*) FILTER (
            WHERE oi.order_id IS NULL
        ) AS null_order_ids,

        -- Check missing product prices.
        COUNT(*) FILTER (
            WHERE oi.price IS NULL
        ) AS null_prices,

        -- Identify zero or negative product prices.
        COUNT(*) FILTER (
            WHERE oi.price <= 0
        ) AS non_positive_prices,

        -- Check missing freight values.
        COUNT(*) FILTER (
            WHERE oi.freight_value IS NULL
        ) AS null_freight_values,

        -- Identify negative freight charges.
        COUNT(*) FILTER (
            WHERE oi.freight_value < 0
        ) AS negative_freight_values,

        -- Check order-item records without matching orders.
        COUNT(*) FILTER (
            WHERE o.order_id IS NULL
        ) AS unmatched_orders

    FROM olist.order_items oi

    LEFT JOIN olist.orders o
        ON oi.order_id = o.order_id
),


-- SECTION 3: Combine payment and order-item audit results.
audit_results AS (

    -- Payment transaction results.
    SELECT
        'Payment Transactions' AS audit_area,
        'Total Records' AS quality_check,
        total_payment_records::TEXT AS result,
        'Reference count of payment records' AS interpretation
    FROM payment_quality

    UNION ALL

    SELECT
        'Payment Transactions',
        'NULL Order IDs',
        null_order_ids::TEXT,
        'Expected: 0'
    FROM payment_quality

    UNION ALL

    SELECT
        'Payment Transactions',
        'NULL Payment Types',
        null_payment_types::TEXT,
        'Expected: 0'
    FROM payment_quality

    UNION ALL

    SELECT
        'Payment Transactions',
        'NULL Payment Values',
        null_payment_values::TEXT,
        'Expected: 0'
    FROM payment_quality

    UNION ALL

    SELECT
        'Payment Transactions',
        'Non-positive Payment Values',
        non_positive_payment_values::TEXT,
        'Investigate zero or negative payment amounts'
    FROM payment_quality

    UNION ALL

    SELECT
        'Payment Transactions',
        'Invalid Installments',
        invalid_installments::TEXT,
        'Investigate non-positive installment counts'
    FROM payment_quality

    UNION ALL

    SELECT
        'Payment Transactions',
        'Unexpected Payment Types',
        unexpected_payment_types::TEXT,
        'Review payment method categories'
    FROM payment_quality

    UNION ALL

    SELECT
        'Payment Transactions',
        'Unmatched Orders',
        unmatched_orders::TEXT,
        'Expected: 0'
    FROM payment_quality

    UNION ALL

    -- Order-item results.
    SELECT
        'Order Items',
        'Total Records',
        total_order_items::TEXT,
        'Reference count of order-item records'
    FROM order_item_quality

    UNION ALL

    SELECT
        'Order Items',
        'NULL Order IDs',
        null_order_ids::TEXT,
        'Expected: 0'
    FROM order_item_quality

    UNION ALL

    SELECT
        'Order Items',
        'NULL Prices',
        null_prices::TEXT,
        'Expected: 0'
    FROM order_item_quality

    UNION ALL

    SELECT
        'Order Items',
        'Non-positive Prices',
        non_positive_prices::TEXT,
        'Investigate zero or negative product prices'
    FROM order_item_quality

    UNION ALL

    SELECT
        'Order Items',
        'NULL Freight Values',
        null_freight_values::TEXT,
        'Expected: 0'
    FROM order_item_quality

    UNION ALL

    SELECT
        'Order Items',
        'Negative Freight Values',
        negative_freight_values::TEXT,
        'Investigate negative freight charges'
    FROM order_item_quality

    UNION ALL

    SELECT
        'Order Items',
        'Unmatched Orders',
        unmatched_orders::TEXT,
        'Expected: 0'
    FROM order_item_quality
)


-- SECTION 4: Display combined audit results.
SELECT
    audit_area,
    quality_check,
    result,
    interpretation

FROM audit_results

ORDER BY
    CASE audit_area
        WHEN 'Payment Transactions' THEN 1
        ELSE 2
    END,

    CASE quality_check
        WHEN 'Total Records' THEN 1
        ELSE 2
    END,

    quality_check;
-- =====================================================
-- SECTION 5: PAYMENT INVESTIGATION FINDINGS
--
-- PAYMENT VALUE FINDINGS:
-- Total non-positive payment records: 9
-- - not_defined: 3 zero-value records
-- - voucher: 6 zero-value records
--
-- INSTALLMENT FINDINGS:
-- Total invalid installment records: 2
-- - Both belong to credit_card payments.
-- - Both have positive payment values.
-- - Both belong to delivered orders.
--
-- ORDER-LEVEL INVESTIGATION:
-- Unique affected orders: 10
-- - Canceled orders: 3
-- - Delivered orders: 6
-- - Shipped orders: 1
--
-- BUSINESS INTERPRETATION:
-- Some zero-value payment entries coexist with
-- positive payments within the same order.
--
-- Zero-value entries should not automatically be
-- treated as invalid financial transactions.
--
-- FINAL CLEANING DECISION:
-- Preserve all original payment records.
-- Do not delete or overwrite source values.
-- Flag invalid installment records for review.
-- =====================================================