SELECT
  CAST(FORMAT_DATE('%Y%m%d', date) AS INT64) AS date_key,
  date,
  ad_spend,
  sku_orders,
  cost_per_order,
  gross_revenue,
  roi,
  currency
FROM {{ source('staging', 'stg_campaign_daily') }}
