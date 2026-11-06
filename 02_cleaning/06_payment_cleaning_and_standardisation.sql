
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 2: Data Cleaning & Quality
-- STEP 6: Payment Cleaning & Standardisation
--
-- PURPOSE:
-- Create a reusable cleaned analytical view for payments.
--
-- IMPORTANT:
-- Original payment records are not modified or deleted.
-- Invalid values are preserved and flagged.
-- =====================================================

-- SECTION 1: Create the cleaned payment view.
CREATE OR REPLACE VIEW olist.vw_payments_cleaned AS

SELECT
    -- Preserve original payment identifiers.
    p.order_id,
    p.payment_sequential,

    -- Standardise payment type formatting.
    LOWER(TRIM(p.payment_type)) AS payment_type,

    -- Preserve original financial values.
    p.payment_installments,
    p.payment_value,

    -- Flag zero or negative payment amounts.
    CASE
        WHEN p.payment_value <= 0
            THEN TRUE
        ELSE FALSE
    END AS non_positive_payment_flag,

    -- Flag invalid installment counts.
    CASE
        WHEN p.payment_installments <= 0
            THEN TRUE
        ELSE FALSE
    END AS invalid_installment_flag,

    -- Flag missing payment information.
    CASE
        WHEN p.payment_type IS NULL
          OR p.payment_value IS NULL
          OR p.payment_installments IS NULL
            THEN TRUE
        ELSE FALSE
    END AS missing_payment_information_flag,

    -- Classify payment amount quality.
    CASE
        WHEN p.payment_value IS NULL
            THEN 'Missing Payment Value'

        WHEN p.payment_value < 0
            THEN 'Negative Payment'

        WHEN p.payment_value = 0
            THEN 'Zero Payment'

        ELSE 'Positive Payment'
    END AS payment_value_status,

    -- Classify installment quality.
    CASE
        WHEN p.payment_installments IS NULL
            THEN 'Missing Installments'

        WHEN p.payment_installments <= 0
            THEN 'Invalid Installments'

        ELSE 'Valid Installments'
    END AS installment_status,

    -- Standardise payment type classification.
    CASE
        WHEN p.payment_type IS NULL
            THEN 'Missing Payment Type'

        WHEN LOWER(TRIM(p.payment_type)) = 'not_defined'
            THEN 'Undefined Payment Type'

        ELSE LOWER(TRIM(p.payment_type))
    END AS payment_type_category,

    -- Preserve the original order status.
    o.order_status,

    -- Flag payment records without a matching order.
    CASE
        WHEN o.order_id IS NULL
            THEN TRUE
        ELSE FALSE
    END AS unmatched_order_flag

FROM olist.order_payments p

LEFT JOIN olist.orders o
    ON p.order_id = o.order_id;


-- SECTION 2: Validate the cleaned payment view.
SELECT
    COUNT(*) AS total_payment_records,

    COUNT(*) FILTER (
        WHERE non_positive_payment_flag
    ) AS non_positive_payment_records,

    COUNT(*) FILTER (
        WHERE invalid_installment_flag
    ) AS invalid_installment_records,

    COUNT(*) FILTER (
        WHERE missing_payment_information_flag
    ) AS missing_information_records,

    COUNT(*) FILTER (
        WHERE unmatched_order_flag
    ) AS unmatched_order_records,

    COUNT(*) FILTER (
        WHERE payment_type_category = 'Undefined Payment Type'
    ) AS undefined_payment_type_records

FROM olist.vw_payments_cleaned;
