WITH order_daily AS (

  SELECT

    date_key,

    order_date AS date,

    COUNT(DISTINCT order_id) AS observed_order_id_count,

    COUNT(*) AS order_item_count,

    SUM(quantity) AS units_ordered,

    SUM(subtotal_before_discount) AS order_item_gross_amount,

    SUM(total_discount) AS order_item_discount_amount,

    SUM(subtotal_after_discount) AS order_item_net_amount,

    SUM(refund_amount) AS order_item_refund_amount

  FROM {{ ref('fact_order_item') }}

  {% if is_incremental() %}
  WHERE order_date >= {{ phase11_incremental_start_date('date') }}
  {% endif %}

  GROUP BY date_key, order_date

),

shop_daily AS (

  SELECT

    date_key,

    date,

    gmv AS shop_reported_gmv,

    orders AS shop_reported_orders,

    customers AS shop_reported_customers,

    units_sold AS shop_reported_units_sold,

    refund_amount AS shop_reported_refund_amount,

    revenue AS shop_reported_revenue,

    page_views AS shop_reported_page_views,

    visitors AS shop_reported_visitors,

    conversion_rate AS shop_reported_conversion_rate,

    aov AS shop_reported_aov

  FROM {{ ref('fact_shop_daily') }}

  {% if is_incremental() %}
  WHERE date >= {{ phase11_incremental_start_date('date') }}
  {% endif %}

),

all_dates AS (

  SELECT date_key, date FROM order_daily

  UNION DISTINCT

  SELECT date_key, date FROM shop_daily

)

SELECT

  d.date_key,

  d.date,

  o.observed_order_id_count,

  o.order_item_count,

  o.units_ordered,

  o.order_item_gross_amount,

  o.order_item_discount_amount,

  o.order_item_net_amount,

  o.order_item_refund_amount,

  s.shop_reported_gmv,

  s.shop_reported_orders,

  s.shop_reported_customers,

  s.shop_reported_units_sold,

  s.shop_reported_refund_amount,

  s.shop_reported_revenue,

  s.shop_reported_page_views,

  s.shop_reported_visitors,

  s.shop_reported_conversion_rate,

  s.shop_reported_aov

FROM all_dates d

LEFT JOIN order_daily o USING (date_key, date)

LEFT JOIN shop_daily s USING (date_key, date)
