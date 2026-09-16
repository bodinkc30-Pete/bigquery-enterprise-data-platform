CREATE OR REPLACE TABLE `{{PROJECT_ID}}.core.fact_campaign_daily`
PARTITION BY date
OPTIONS(description="Daily aggregate campaign-performance fact; no campaign dimension because source has no business key.") AS
SELECT
  CAST(FORMAT_DATE('%Y%m%d', date) AS INT64) AS date_key,
  date,
  ad_spend,
  sku_orders,
  cost_per_order,
  gross_revenue,
  roi,
  currency
FROM `{{PROJECT_ID}}.staging.stg_campaign_daily`;
