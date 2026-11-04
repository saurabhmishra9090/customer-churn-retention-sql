
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- TABLE: sellers
-- PURPOSE: Create seller master table
-- =====================================================

CREATE TABLE IF NOT EXISTS olist.sellers (
    seller_id VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(5),
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);
