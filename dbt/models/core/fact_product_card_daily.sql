SELECT
  CAST(FORMAT_DATE('%Y%m%d', date) AS INT64) AS date_key,
  date,
  views,
  clicks,
  customers,
  sku_orders,
  product_card_gmv,
  checkout_cart_rate,
  viewers,
  add_to_cart_clicks,
  unique_clicks,
  cart_customers,
  click_to_cart_rate,
  view_to_click_rate,
  view_to_checkout_rate,
  click_to_checkout_rate,
  content_gmv
FROM {{ source('staging', 'stg_product_card_daily') }}
