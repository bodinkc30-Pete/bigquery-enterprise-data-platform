CREATE OR REPLACE TABLE `{{PROJECT_ID}}.core.dim_channel`
OPTIONS(description="Conformed commerce order-channel dimension.") AS
SELECT
  TO_HEX(SHA256(CONCAT('channel|', order_channel))) AS channel_key,
  order_channel AS channel_name
FROM `{{PROJECT_ID}}.staging.stg_orders`
WHERE order_channel IS NOT NULL
GROUP BY order_channel;
