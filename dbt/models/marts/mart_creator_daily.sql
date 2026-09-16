WITH order_activity AS (

  SELECT

    date_key,

    creator_key,

    COUNT(DISTINCT order_id) AS observed_order_id_count,

    COUNT(*) AS order_item_count,

    SUM(quantity) AS units_ordered,

    SUM(subtotal_after_discount) AS order_item_net_amount,

    SUM(refund_amount) AS order_item_refund_amount

  FROM {{ ref('fact_order_item') }}

  WHERE creator_key IS NOT NULL
  {% if is_incremental() %}
    AND order_date >= {{ phase11_incremental_start_date('date') }}
  {% endif %}

  GROUP BY date_key, creator_key

),

payment_activity AS (

  SELECT

    date_key,

    creator_key,

    COUNT(*) AS payment_count,

    SUM(payment_amount) AS payment_amount

  FROM {{ ref('fact_creator_payment') }}

  {% if is_incremental() %}
  WHERE post_date >= {{ phase11_incremental_start_date('date') }}
  {% endif %}

  GROUP BY date_key, creator_key

),

keys AS (

  SELECT date_key, creator_key FROM order_activity

  UNION DISTINCT

  SELECT date_key, creator_key FROM payment_activity

)

SELECT

  k.date_key,

  d.date,

  k.creator_key,

  c.historical_sales_band,

  c.audience_gender_segment,

  c.audience_age_segment,

  c.pet_segment,

  o.observed_order_id_count,

  o.order_item_count,

  o.units_ordered,

  o.order_item_net_amount,

  o.order_item_refund_amount,

  p.payment_count,

  p.payment_amount

FROM keys k

JOIN {{ ref('dim_date') }} d USING (date_key)

JOIN {{ ref('dim_creator') }} c USING (creator_key)

LEFT JOIN order_activity o USING (date_key, creator_key)

LEFT JOIN payment_activity p USING (date_key, creator_key)
