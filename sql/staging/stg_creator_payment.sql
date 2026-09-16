CREATE OR REPLACE TABLE `{{PROJECT_ID}}.staging.stg_creator_payment` AS
SELECT
  `payment_id` AS `payment_id`,
  `creator_token` AS `creator_token`,
  SAFE_CAST(`payment_amount` AS NUMERIC) AS `payment_amount`,
  SAFE_CAST(`post_date` AS DATE) AS `post_date`,
  `settlement_account_token` AS `settlement_account_token`,
  `payment_cycle` AS `payment_cycle`,
  `payment_status` AS `payment_status`,
  `payment_type` AS `payment_type`,
  `source_reference_token` AS `source_reference_token`,
  CURRENT_TIMESTAMP() AS `_ingested_at`,
  'creator_payment_synthetic.csv' AS `_source_file`,
  'phase07-bootstrap-v1' AS `_run_id`,
  TO_HEX(SHA256(CONCAT(COALESCE(`payment_id`, ''), COALESCE(`creator_token`, ''), COALESCE(`payment_amount`, ''), COALESCE(`post_date`, ''), COALESCE(`settlement_account_token`, ''), COALESCE(`payment_cycle`, ''), COALESCE(`payment_status`, ''), COALESCE(`payment_type`, ''), COALESCE(`source_reference_token`, '')))) AS `_record_hash`
FROM `{{PROJECT_ID}}.raw.creator_payment`;
