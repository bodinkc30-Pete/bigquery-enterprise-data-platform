CREATE OR REPLACE TABLE `{{PROJECT_ID}}.core.dim_product`
OPTIONS(description="Conformed product dimension with stable technical keys.") AS
WITH product_rollup AS (
  SELECT
    product_id,
    ARRAY_AGG(STRUCT(product_name, status) ORDER BY sku_id LIMIT 1)[OFFSET(0)] AS attrs,
    COUNT(*) AS sku_count
  FROM `{{PROJECT_ID}}.staging.stg_product_sku`
  GROUP BY product_id
)
SELECT
  TO_HEX(SHA256(CONCAT('product|', product_id))) AS product_key,
  product_id,
  attrs.product_name AS product_name,
  attrs.status AS status,
  sku_count
FROM product_rollup;
