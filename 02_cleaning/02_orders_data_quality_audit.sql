
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 2: Data Cleaning & Quality
-- STEP 2: Orders Data Quality Audit
--
-- PURPOSE:
-- Identify missing order information, invalid dates,
-- unexpected statuses, and delivery date inconsistencies.
--
-- IMPORTANT:
-- This is an audit query. It does not modify data.
-- =====================================================

-- SECTION 1: Calculate order data quality metrics.
WITH order_quality AS (

    SELECT
        COUNT(*) AS total_orders,

        -- Check missing identifiers and purchase dates.
        COUNT(*) FILTER (
            WHERE order_id IS NULL
        ) AS null_order_ids,

        COUNT(*) FILTER (
            WHERE customer_id IS NULL
        ) AS null_customer_ids,

        COUNT(*) FILTER (
            WHERE order_purchase_timestamp IS NULL
        ) AS null_purchase_dates,

        -- Check missing delivery-related dates.
        COUNT(*) FILTER (
            WHERE order_approved_at IS NULL
        ) AS null_approval_dates,

        COUNT(*) FILTER (
            WHERE order_delivered_carrier_date IS NULL
        ) AS null_carrier_dates,

        COUNT(*) FILTER (
            WHERE order_delivered_customer_date IS NULL
        ) AS null_delivery_dates,

        COUNT(*) FILTER (
            WHERE order_estimated_delivery_date IS NULL
        ) AS null_estimated_dates,

        -- Check unexpected order statuses.
        COUNT(*) FILTER (
            WHERE order_status NOT IN (
                'created',
                'approved',
                'invoiced',
                'processing',
                'shipped',
                'delivered',
                'canceled',
                'unavailable'
            )
            OR order_status IS NULL
        ) AS invalid_order_statuses,

        -- Check logical timestamp inconsistencies.
        COUNT(*) FILTER (
            WHERE order_approved_at < order_purchase_timestamp
        ) AS approval_before_purchase,

        COUNT(*) FILTER (
            WHERE order_delivered_carrier_date < order_approved_at
        ) AS carrier_before_approval,

        COUNT(*) FILTER (
            WHERE order_delivered_customer_date
                  < order_delivered_carrier_date
        ) AS delivery_before_carrier,

        COUNT(*) FILTER (
            WHERE order_delivered_customer_date
                  < order_purchase_timestamp
        ) AS delivery_before_purchase,

        COUNT(*) FILTER (
            WHERE order_delivered_customer_date
                  > order_estimated_delivery_date
        ) AS delivered_after_estimated_date

    FROM olist.orders
)

-- SECTION 2: Display the audit results.
SELECT
    'Total Orders' AS quality_check,
    total_orders::TEXT AS result,
    'Reference count of order records' AS interpretation
FROM order_quality

UNION ALL

SELECT
    'NULL Order IDs',
    null_order_ids::TEXT,
    'Expected: 0'
FROM order_quality

UNION ALL

SELECT
    'NULL Customer IDs',
    null_customer_ids::TEXT,
    'Expected: 0'
FROM order_quality

UNION ALL

SELECT
    'NULL Purchase Dates',
    null_purchase_dates::TEXT,
    'Expected: 0'
FROM order_quality

UNION ALL

SELECT
    'NULL Approval Dates',
    null_approval_dates::TEXT,
    'May occur for orders that were not approved'
FROM order_quality

UNION ALL

SELECT
    'NULL Carrier Dates',
    null_carrier_dates::TEXT,
    'May occur for orders that were not shipped'
FROM order_quality

UNION ALL

SELECT
    'NULL Delivery Dates',
    null_delivery_dates::TEXT,
    'May occur for orders not yet delivered'
FROM order_quality

UNION ALL

SELECT
    'NULL Estimated Delivery Dates',
    null_estimated_dates::TEXT,
    'Review missing estimated delivery information'
FROM order_quality

UNION ALL

SELECT
    'Invalid Order Statuses',
    invalid_order_statuses::TEXT,
    'Expected: 0'
FROM order_quality

UNION ALL

SELECT
    'Approval Before Purchase',
    approval_before_purchase::TEXT,
    'Expected: 0'
FROM order_quality

UNION ALL

SELECT
    'Carrier Before Approval',
    carrier_before_approval::TEXT,
    'Expected: 0'
FROM order_quality

UNION ALL

SELECT
    'Delivery Before Carrier',
    delivery_before_carrier::TEXT,
    'Expected: 0'
FROM order_quality

UNION ALL

SELECT
    'Delivery Before Purchase',
    delivery_before_purchase::TEXT,
    'Expected: 0'
FROM order_quality

UNION ALL

SELECT
    'Delivered After Estimated Date',
    delivered_after_estimated_date::TEXT,
    'Orders delivered later than estimated'
FROM order_quality;
-- =====================================================
-- SECTION 3: DATA QUALITY INVESTIGATION FINDINGS
--
-- AUDIT RESULTS (Olist dataset):
--
-- 1. Total orders: 99,441
--
-- 2. Missing dates:
--    - Approval dates: 160
--    - Carrier dates: 1,783
--    - Customer delivery dates: 2,965
--
--    These missing values require order-status context.
--
-- 3. Timestamp inconsistencies:
--    - Carrier date before approval: 1,359 records
--    - Customer delivery before carrier: 23 records
--
-- 4. Late deliveries:
--    - Delivered after estimated date: 7,827 records
--
-- BUSINESS INTERPRETATION:
-- Timestamp inconsistencies require investigation.
-- Late delivery is an operational performance indicator,
-- not automatically a data-quality error.
--
-- DECISION:
-- No source records have been modified or deleted.
-- Original timestamps are preserved.
-- =====================================================
-- =====================================================
-- SECTION 3: INVESTIGATION FINDINGS
--
-- DATASET AUDIT RESULTS:
--
-- Total orders: 99,441
-- NULL approval dates: 160
-- NULL carrier dates: 1,783
-- NULL delivery dates: 2,965
--
-- TIMESTAMP INCONSISTENCIES:
-- Carrier before approval: 1,359
-- Carrier before purchase: 166
-- Delivery before carrier: 23
--
-- DELIVERY PERFORMANCE:
-- Delivered after estimated date: 7,827
--
-- INVESTIGATION:
-- 1,350 carrier-before-approval records are delivered.
-- 9 carrier-before-approval records are shipped.
--
-- 166 records have carrier timestamps before purchase.
-- The largest observed gap is approximately 171 days.
--
-- DATA QUALITY DECISION:
-- Preserve all original timestamps.
-- Do not automatically update or delete records.
-- Flag inconsistent timestamps for further review.
--
-- Late delivery is an operational performance indicator,
-- not automatically a data-quality error.
-- =====================================================
-- =====================================================
-- SECTION 3: INVESTIGATION FINDINGS
--
-- Carrier timestamp before approval:
-- Total affected orders: 1,359
-- Delivered orders: 1,350
-- Shipped orders: 9
--
-- Average hours before approval:
-- Delivered: 24.70 hours
-- Shipped: 32.10 hours
--
-- Maximum hours before approval:
-- Delivered: 4,109.26 hours
-- Shipped: 98.32 hours
--
-- Additional investigation:
-- Top 10 affected records were inspected.
-- One record showed carrier handover approximately
-- 171 days before the purchase timestamp.
--
-- Another group of records showed carrier handover
-- around 4-5 September 2017, while approval was
-- recorded on 13 September 2017.
--
-- BUSINESS DECISION:
-- These records require source-data investigation.
-- No timestamps have been modified or deleted.
-- Original source values are preserved.
--
-- Late deliveries (7,827 records) are treated as
-- operational performance indicators, not automatic
-- data-quality errors.
-- =====================================================
-- =====================================================
-- SECTION 4: DELIVERY TIMESTAMP INVESTIGATION
--
-- Delivery timestamp earlier than carrier timestamp:
-- Total affected records: 23
-- Delivered status: 23
--
-- BUSINESS INTERPRETATION:
-- All 23 affected records belong to delivered orders.
-- These are potential timestamp inconsistencies.
--
-- FINAL DATA CLEANING DECISION:
-- Preserve all original timestamps.
-- Do not delete or overwrite source records.
-- Flag these records for further investigation.
-- =====================================================