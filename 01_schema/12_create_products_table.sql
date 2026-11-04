
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- TABLE: products
-- PURPOSE: Create product master table
-- =====================================================

CREATE TABLE IF NOT EXISTS olist.products (
    product_id VARCHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);
