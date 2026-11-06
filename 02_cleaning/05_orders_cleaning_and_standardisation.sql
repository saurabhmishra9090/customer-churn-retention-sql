
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- PHASE 2: Data Cleaning & Quality
-- STEP 5: Orders Cleaning & Standardisation
--
-- PURPOSE:
-- Create a reusable cleaned analytical view for orders.
--
-- IMPORTANT:
-- Original olist.orders table is not modified.
-- Original timestamps are preserved.
-- =====================================================

-- SECTION 1: Create a cleaned analytical view.
CREATE OR REPLACE VIEW olist.vw_orders_cleaned AS

SELECT
    -- Preserve original order identifiers.
    order_id,
    customer_id,

    -- Standardise order status formatting.
    LOWER(TRIM(order_status)) AS order_status,

    -- Preserve original timestamps.
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    -- Flag missing critical information.
    CASE
        WHEN order_purchase_timestamp IS NULL
            THEN TRUE
        ELSE FALSE
    END AS missing_purchase_timestamp,

    -- Flag carrier handover before approval.
    CASE
        WHEN order_delivered_carrier_date
             < order_approved_at
            THEN TRUE
        ELSE FALSE
    END AS carrier_before_approval_flag,

    -- Flag customer delivery before carrier handover.
    CASE
        WHEN order_delivered_customer_date
             < order_delivered_carrier_date
            THEN TRUE
        ELSE FALSE
    END AS delivery_before_carrier_flag,

    -- Flag customer delivery before purchase.
    CASE
        WHEN order_delivered_customer_date
             < order_purchase_timestamp
            THEN TRUE
        ELSE FALSE
    END AS delivery_before_purchase_flag,

    -- Calculate delivery delay in days.
    CASE
        WHEN order_delivered_customer_date IS NOT NULL
         AND order_estimated_delivery_date IS NOT NULL
        THEN
            order_delivered_customer_date::DATE
            - order_estimated_delivery_date::DATE
        ELSE NULL
    END AS delivery_delay_days,

   -- Classify delivery performance using full timestamps.
CASE
    WHEN order_delivered_customer_date IS NULL
        THEN 'Not Delivered'

    WHEN order_estimated_delivery_date IS NULL
        THEN 'Estimate Unavailable'

    WHEN order_delivered_customer_date
         > order_estimated_delivery_date
        THEN 'Late Delivery'

    ELSE 'On-Time or Early Delivery'
END AS delivery_performance_status,
    -- Assign an overall timestamp quality flag.
    CASE
        WHEN order_delivered_carrier_date
             < order_approved_at
          OR order_delivered_customer_date
             < order_delivered_carrier_date
          OR order_delivered_customer_date
             < order_purchase_timestamp
            THEN 'Timestamp Anomaly'

        ELSE 'No Detected Timestamp Anomaly'
    END AS timestamp_quality_status

FROM olist.orders;


-- SECTION 2: Validate the cleaned view.
SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE carrier_before_approval_flag
    ) AS carrier_before_approval_records,

    COUNT(*) FILTER (
        WHERE delivery_before_carrier_flag
    ) AS delivery_before_carrier_records,

    COUNT(*) FILTER (
        WHERE delivery_before_purchase_flag
    ) AS delivery_before_purchase_records,

    COUNT(*) FILTER (
        WHERE delivery_performance_status = 'Late Delivery'
    ) AS late_delivery_records,

    COUNT(*) FILTER (
        WHERE timestamp_quality_status = 'Timestamp Anomaly'
    ) AS timestamp_anomaly_records

FROM olist.vw_orders_cleaned;
