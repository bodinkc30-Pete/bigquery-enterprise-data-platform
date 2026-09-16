CREATE OR REPLACE TABLE `{{PROJECT_ID}}.staging.stg_product_sku` AS
SELECT
  `sku_id` AS `sku_id`,
  `product_id` AS `product_id`,
  `product_name` AS `product_name`,
  `status` AS `status`,
  SAFE_CAST(`gmv` AS NUMERIC) AS `gmv`,
  SAFE_CAST(`sku_orders` AS INT64) AS `sku_orders`,
  SAFE_CAST(`units_sold` AS INT64) AS `units_sold`,
  CURRENT_TIMESTAMP() AS `_ingested_at`,
  'product_sku_synthetic.csv' AS `_source_file`,
  'phase07-bootstrap-v1' AS `_run_id`,
  TO_HEX(SHA256(CONCAT(COALESCE(`sku_id`, ''), COALESCE(`product_id`, ''), COALESCE(`product_name`, ''), COALESCE(`status`, ''), COALESCE(`gmv`, ''), COALESCE(`sku_orders`, ''), COALESCE(`units_sold`, '')))) AS `_record_hash`
FROM `{{PROJECT_ID}}.raw.product_sku`;
