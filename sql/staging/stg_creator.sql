CREATE OR REPLACE TABLE `{{PROJECT_ID}}.staging.stg_creator` AS
SELECT
  `creator_token` AS `creator_token`,
  SAFE_CAST(`follower_count` AS INT64) AS `follower_count`,
  SAFE_CAST(`engagement_rate` AS NUMERIC) AS `engagement_rate`,
  SAFE_CAST(`synthetic_budget` AS NUMERIC) AS `synthetic_budget`,
  `historical_sales_band` AS `historical_sales_band`,
  `audience_gender_segment` AS `audience_gender_segment`,
  `audience_age_segment` AS `audience_age_segment`,
  `pet_segment` AS `pet_segment`,
  CURRENT_TIMESTAMP() AS `_ingested_at`,
  'creator_synthetic.csv' AS `_source_file`,
  'phase07-bootstrap-v1' AS `_run_id`,
  TO_HEX(SHA256(CONCAT(COALESCE(`creator_token`, ''), COALESCE(`follower_count`, ''), COALESCE(`engagement_rate`, ''), COALESCE(`synthetic_budget`, ''), COALESCE(`historical_sales_band`, ''), COALESCE(`audience_gender_segment`, ''), COALESCE(`audience_age_segment`, ''), COALESCE(`pet_segment`, '')))) AS `_record_hash`
FROM `{{PROJECT_ID}}.raw.creator`;
