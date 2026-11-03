-- Price and freight validation

SELECT
    COUNT(*) AS total_items,
    COUNT(*) FILTER (
        WHERE price <= 0
    ) AS invalid_prices,
    COUNT(*) FILTER (
        WHERE freight_value < 0
    ) AS invalid_freight,
    ROUND(SUM(price), 2) AS total_product_revenue,
    ROUND(SUM(freight_value), 2) AS total_freight
FROM olist.order_items;