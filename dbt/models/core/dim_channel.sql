SELECT
  TO_HEX(SHA256(CONCAT('channel|', order_channel))) AS channel_key,
  order_channel AS channel_name
FROM {{ source('staging', 'stg_orders') }}
WHERE order_channel IS NOT NULL
GROUP BY order_channel
