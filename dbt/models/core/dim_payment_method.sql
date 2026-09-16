SELECT
  TO_HEX(SHA256(CONCAT('payment_method|', payment_method))) AS payment_method_key,
  payment_method
FROM {{ source('staging', 'stg_orders') }}
WHERE payment_method IS NOT NULL
GROUP BY payment_method
