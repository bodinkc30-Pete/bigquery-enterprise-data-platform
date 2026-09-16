CREATE OR REPLACE TABLE `{{PROJECT_ID}}.core.dim_sku`
OPTIONS(description="Conformed SKU dimension linked to product by stable technical key.") AS
SELECT
  TO_HEX(SHA256(CONCAT('sku|', sku_id))) AS sku_key,
  sku_id,
  TO_HEX(SHA256(CONCAT('product|', product_id))) AS product_key,
  product_id,
  product_name,
  status
FROM `{{PROJECT_ID}}.staging.stg_product_sku`;
