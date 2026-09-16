CREATE OR REPLACE TABLE `{{PROJECT_ID}}.core.fact_creator_payment`
PARTITION BY post_date
CLUSTER BY creator_key, payment_status, payment_cycle
OPTIONS(description="Creator-payment fact at one row per payment_id using corrected synthetic dates.") AS
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
FROM `{{PROJECT_ID}}.staging.stg_creator_payment`;
