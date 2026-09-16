{{ config(tags=['phase10']) }}

SELECT
  date_key,
  payment_cycle,
  payment_status,
  payment_type,
  COUNT(*) AS row_count
FROM {{ ref('mart_payment_daily') }}
GROUP BY date_key, payment_cycle, payment_status, payment_type
HAVING COUNT(*) > 1
