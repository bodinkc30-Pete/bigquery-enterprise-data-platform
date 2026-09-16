SELECT
  TO_HEX(SHA256(CONCAT('payment|', payment_id))) AS payment_key,
  payment_id,
  TO_HEX(SHA256(CONCAT('creator|', creator_token))) AS creator_key,
  creator_token,
  CAST(FORMAT_DATE('%Y%m%d', post_date) AS INT64) AS date_key,
  post_date,
  payment_amount,
  settlement_account_token,
  payment_cycle,
  payment_status,
  payment_type,
  source_reference_token
FROM {{ source('staging', 'stg_creator_payment') }}
