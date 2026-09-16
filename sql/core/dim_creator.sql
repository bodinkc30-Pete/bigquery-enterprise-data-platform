CREATE OR REPLACE TABLE `{{PROJECT_ID}}.core.dim_creator`
OPTIONS(description="Portfolio-safe creator dimension keyed by tokenized creator identity.") AS
SELECT
  TO_HEX(SHA256(CONCAT('creator|', creator_token))) AS creator_key,
  creator_token,
  follower_count,
  engagement_rate,
  synthetic_budget,
  historical_sales_band,
  audience_gender_segment,
  audience_age_segment,
  pet_segment
FROM `{{PROJECT_ID}}.staging.stg_creator`;
