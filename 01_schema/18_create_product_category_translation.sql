
-- =====================================================
-- PROJECT: Customer Churn & Retention Intelligence
-- TABLE: product_category_translation
-- PURPOSE: Translate Portuguese categories into English
-- =====================================================

CREATE TABLE IF NOT EXISTS olist.product_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100) NOT NULL
);
