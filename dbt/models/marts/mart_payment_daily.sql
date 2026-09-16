SELECT
  date_key,
  post_date,
  payment_cycle,
  payment_status,
  payment_type,
  COUNT(*) AS payment_count,
  COUNT(DISTINCT creator_key) AS creator_count,
  SUM(payment_amount) AS total_payment_amount
FROM {{ ref('fact_creator_payment') }}
{% if is_incremental() %}
WHERE post_date >= {{ phase11_incremental_start_date('post_date') }}
{% endif %}
GROUP BY
  date_key,
  post_date,
  payment_cycle,
  payment_status,
  payment_type
