CREATE OR REPLACE TABLE `{{PROJECT_ID}}.core.fact_shop_daily`
PARTITION BY date
OPTIONS(description="Daily shop performance fact at one row per business date.") AS
SELECT
  CAST(FORMAT_DATE('%Y%m%d', date) AS INT64) AS date_key,
  date,
  gmv,
  orders,
  customers,
  units_sold,
  refund_amount,
  sku_orders,
  revenue,
  page_views,
  visitors,
  conversion_rate,
  product_impressions,
  unique_product_impressions,
  product_clicks,
  unique_product_clicks,
  aov,
  live_creator_gmv,
  video_affiliate_gmv
FROM `{{PROJECT_ID}}.staging.stg_shop_daily`;
