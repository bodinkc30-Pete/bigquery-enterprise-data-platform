WITH business_dates AS (
  SELECT DATE(created_at) AS date FROM {{ source('staging', 'stg_orders') }} WHERE created_at IS NOT NULL
  UNION DISTINCT SELECT date FROM {{ source('staging', 'stg_shop_daily') }} WHERE date IS NOT NULL
  UNION DISTINCT SELECT date FROM {{ source('staging', 'stg_campaign_daily') }} WHERE date IS NOT NULL
  UNION DISTINCT SELECT date FROM {{ source('staging', 'stg_live_daily') }} WHERE date IS NOT NULL
  UNION DISTINCT SELECT date FROM {{ source('staging', 'stg_product_card_daily') }} WHERE date IS NOT NULL
  UNION DISTINCT SELECT post_date FROM {{ source('staging', 'stg_creator_payment') }} WHERE post_date IS NOT NULL
)
SELECT
  CAST(FORMAT_DATE('%Y%m%d', date) AS INT64) AS date_key,
  date,
  EXTRACT(YEAR FROM date) AS year,
  EXTRACT(QUARTER FROM date) AS quarter,
  EXTRACT(MONTH FROM date) AS month,
  FORMAT_DATE('%B', date) AS month_name,
  EXTRACT(DAY FROM date) AS day,
  EXTRACT(DAYOFWEEK FROM date) AS day_of_week,
  FORMAT_DATE('%A', date) AS day_name,
  EXTRACT(ISOWEEK FROM date) AS iso_week,
  EXTRACT(DAYOFWEEK FROM date) IN (1, 7) AS is_weekend
FROM business_dates
