CREATE OR REPLACE TABLE `{{PROJECT_ID}}.staging.stg_campaign_daily` AS
SELECT
  SAFE_CAST(`date` AS DATE) AS `date`,
  SAFE_CAST(`ad_spend` AS NUMERIC) AS `ad_spend`,
  SAFE_CAST(`sku_orders` AS INT64) AS `sku_orders`,
  SAFE_CAST(`cost_per_order` AS NUMERIC) AS `cost_per_order`,
  SAFE_CAST(`gross_revenue` AS NUMERIC) AS `gross_revenue`,
  SAFE_CAST(`roi` AS NUMERIC) AS `roi`,
  `currency` AS `currency`,
  CURRENT_TIMESTAMP() AS `_ingested_at`,
  'campaign_daily_synthetic.csv' AS `_source_file`,
  'phase07-bootstrap-v1' AS `_run_id`,
  TO_HEX(SHA256(CONCAT(COALESCE(`date`, ''), COALESCE(`ad_spend`, ''), COALESCE(`sku_orders`, ''), COALESCE(`cost_per_order`, ''), COALESCE(`gross_revenue`, ''), COALESCE(`roi`, ''), COALESCE(`currency`, '')))) AS `_record_hash`
FROM `{{PROJECT_ID}}.raw.campaign_daily`;
