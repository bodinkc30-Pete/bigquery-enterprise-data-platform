{{ config(tags=['phase10']) }}

WITH source_total AS (
  SELECT
    COUNT(*) AS payment_count,
    SUM(payment_amount) AS payment_amount
  FROM {{ ref('fact_creator_payment') }}
),
mart_total AS (
  SELECT
    SUM(payment_count) AS payment_count,
    SUM(total_payment_amount) AS payment_amount
  FROM {{ ref('mart_payment_daily') }}
)
SELECT
  s.payment_count AS source_payment_count,
  m.payment_count AS mart_payment_count,
  s.payment_amount AS source_payment_amount,
  m.payment_amount AS mart_payment_amount
FROM source_total s
CROSS JOIN mart_total m
WHERE s.payment_count != m.payment_count
   OR ABS(s.payment_amount - m.payment_amount) > 0.01
