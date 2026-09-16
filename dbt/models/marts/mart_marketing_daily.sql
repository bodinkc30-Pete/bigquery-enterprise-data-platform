WITH campaign AS (
  SELECT
    date_key,
    date,
    ad_spend AS campaign_ad_spend,
    sku_orders AS campaign_sku_orders,
    cost_per_order AS campaign_cost_per_order,
    gross_revenue AS campaign_gross_revenue,
    roi AS campaign_roi,
    currency AS campaign_currency
  FROM {{ ref('fact_campaign_daily') }}
  {% if is_incremental() %}
  WHERE date >= {{ phase11_incremental_start_date('date') }}
  {% endif %}
),
live AS (
  SELECT
    date_key,
    date,
    live_gmv,
    direct_live_gmv,
    indirect_live_gmv,
    display_gpm,
    live_streams,
    gmv_live_streams,
    attributed_units AS live_attributed_units,
    customers AS live_customers,
    live_ctr,
    live_ctor,
    live_views,
    avg_watch_duration AS live_avg_watch_duration
  FROM {{ ref('fact_live_daily') }}
  {% if is_incremental() %}
  WHERE date >= {{ phase11_incremental_start_date('date') }}
  {% endif %}
),
product_card AS (
  SELECT
    date_key,
    date,
    views AS product_card_views,
    clicks AS product_card_clicks,
    customers AS product_card_customers,
    sku_orders AS product_card_sku_orders,
    product_card_gmv,
    checkout_cart_rate AS product_card_checkout_cart_rate,
    viewers AS product_card_viewers,
    content_gmv AS product_card_content_gmv
  FROM {{ ref('fact_product_card_daily') }}
  {% if is_incremental() %}
  WHERE date >= {{ phase11_incremental_start_date('date') }}
  {% endif %}
),
all_dates AS (
  SELECT date_key, date FROM campaign
  UNION DISTINCT SELECT date_key, date FROM live
  UNION DISTINCT SELECT date_key, date FROM product_card
)
SELECT
  d.date_key,
  d.date,
  c.campaign_ad_spend,
  c.campaign_sku_orders,
  c.campaign_cost_per_order,
  c.campaign_gross_revenue,
  c.campaign_roi,
  c.campaign_currency,
  l.live_gmv,
  l.direct_live_gmv,
  l.indirect_live_gmv,
  l.display_gpm,
  l.live_streams,
  l.gmv_live_streams,
  l.live_attributed_units,
  l.live_customers,
  l.live_ctr,
  l.live_ctor,
  l.live_views,
  l.live_avg_watch_duration,
  p.product_card_views,
  p.product_card_clicks,
  p.product_card_customers,
  p.product_card_sku_orders,
  p.product_card_gmv,
  p.product_card_checkout_cart_rate,
  p.product_card_viewers,
  p.product_card_content_gmv
FROM all_dates d
LEFT JOIN campaign c USING (date_key, date)
LEFT JOIN live l USING (date_key, date)
LEFT JOIN product_card p USING (date_key, date)
