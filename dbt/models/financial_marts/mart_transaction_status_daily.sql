SELECT
  DATE(initiated_at) AS business_date,
  currency,
  status AS transaction_status,
  COUNT(*) AS transaction_count,
  SUM(transaction_amount_minor) AS transaction_amount_minor
FROM {{ source('financial_ops_synth', 'transactions') }}
{% if is_incremental() %}
WHERE DATE(initiated_at) >= {{ phase27_incremental_start_date('business_date') }}
{% endif %}
GROUP BY 1,2,3
