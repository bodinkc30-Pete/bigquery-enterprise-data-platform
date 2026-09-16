SELECT
  TO_HEX(SHA256(CONCAT('sku|', sku_id))) AS sku_key,
  sku_id,
  TO_HEX(SHA256(CONCAT('product|', product_id))) AS product_key,
  product_id,
  product_name,
  status
FROM {{ source('staging', 'stg_product_sku') }}
