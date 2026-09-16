CREATE OR REPLACE TABLE `{{PROJECT_ID}}.core.fact_live_daily`
PARTITION BY date
OPTIONS(description="Daily LIVE commerce performance fact at one row per business date.") AS
SELECT
  CAST(FORMAT_DATE('%Y%m%d', date) AS INT64) AS date_key,
  date,
  live_gmv,
  direct_live_gmv,
  indirect_live_gmv,
  display_gpm,
  live_streams,
  gmv_live_streams,
  attributed_units,
  direct_units,
  indirect_units,
  attributed_sku_orders,
  direct_sku_orders,
  indirect_sku_orders,
  customers,
  live_ctr,
  live_ctor,
  live_views,
  avg_watch_duration
FROM `{{PROJECT_ID}}.staging.stg_live_daily`;
