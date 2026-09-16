CREATE OR REPLACE TABLE `{{PROJECT_ID}}.staging.stg_product_card_daily` AS
SELECT
  SAFE_CAST(`date` AS DATE) AS `date`,
  SAFE_CAST(`views` AS INT64) AS `views`,
  SAFE_CAST(`clicks` AS INT64) AS `clicks`,
  SAFE_CAST(`customers` AS INT64) AS `customers`,
  SAFE_CAST(`sku_orders` AS INT64) AS `sku_orders`,
  SAFE_CAST(`product_card_gmv` AS NUMERIC) AS `product_card_gmv`,
  SAFE_CAST(`checkout_cart_rate` AS NUMERIC) AS `checkout_cart_rate`,
  SAFE_CAST(`viewers` AS INT64) AS `viewers`,
  SAFE_CAST(`add_to_cart_clicks` AS INT64) AS `add_to_cart_clicks`,
  SAFE_CAST(`unique_clicks` AS INT64) AS `unique_clicks`,
  SAFE_CAST(`cart_customers` AS INT64) AS `cart_customers`,
  SAFE_CAST(`click_to_cart_rate` AS NUMERIC) AS `click_to_cart_rate`,
  SAFE_CAST(`view_to_click_rate` AS NUMERIC) AS `view_to_click_rate`,
  SAFE_CAST(`view_to_checkout_rate` AS NUMERIC) AS `view_to_checkout_rate`,
  SAFE_CAST(`click_to_checkout_rate` AS NUMERIC) AS `click_to_checkout_rate`,
  SAFE_CAST(`content_gmv` AS NUMERIC) AS `content_gmv`,
  CURRENT_TIMESTAMP() AS `_ingested_at`,
  'product_card_daily_synthetic.csv' AS `_source_file`,
  'phase07-bootstrap-v1' AS `_run_id`,
  TO_HEX(SHA256(CONCAT(COALESCE(`date`, ''), COALESCE(`views`, ''), COALESCE(`clicks`, ''), COALESCE(`customers`, ''), COALESCE(`sku_orders`, ''), COALESCE(`product_card_gmv`, ''), COALESCE(`checkout_cart_rate`, ''), COALESCE(`viewers`, ''), COALESCE(`add_to_cart_clicks`, ''), COALESCE(`unique_clicks`, ''), COALESCE(`cart_customers`, ''), COALESCE(`click_to_cart_rate`, ''), COALESCE(`view_to_click_rate`, ''), COALESCE(`view_to_checkout_rate`, ''), COALESCE(`click_to_checkout_rate`, ''), COALESCE(`content_gmv`, '')))) AS `_record_hash`
FROM `{{PROJECT_ID}}.raw.product_card_daily`;
