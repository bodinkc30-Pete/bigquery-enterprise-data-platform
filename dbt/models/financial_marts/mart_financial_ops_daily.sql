WITH completed_transactions AS (
  SELECT DATE(initiated_at) AS business_date, currency,
         COUNT(*) AS transaction_count,
         SUM(transaction_amount_minor) AS transaction_amount_minor
  FROM {{ source('financial_ops_synth', 'transactions') }}
  WHERE status = 'COMPLETED'
  {% if is_incremental() %}
    AND DATE(initiated_at) >= {{ phase27_incremental_start_date('business_date') }}
  {% endif %}
  GROUP BY 1,2
), refunds AS (
  SELECT DATE(requested_at) AS business_date, currency,
         COUNT(*) AS refund_count, SUM(refund_amount_minor) AS refund_amount_minor
  FROM {{ source('financial_ops_synth', 'refunds') }}
  {% if is_incremental() %}
  WHERE DATE(requested_at) >= {{ phase27_incremental_start_date('business_date') }}
  {% endif %}
  GROUP BY 1,2
), reversals AS (
  SELECT DATE(created_at) AS business_date, currency,
         COUNT(*) AS reversal_count, SUM(reversal_amount_minor) AS reversal_amount_minor
  FROM {{ source('financial_ops_synth', 'reversals') }}
  {% if is_incremental() %}
  WHERE DATE(created_at) >= {{ phase27_incremental_start_date('business_date') }}
  {% endif %}
  GROUP BY 1,2
), settlements AS (
  SELECT settlement_date AS business_date, currency,
         COUNT(*) AS settlement_item_count, SUM(net_amount_minor) AS settlement_net_amount_minor
  FROM {{ source('financial_ops_synth', 'settlement_items') }}
  {% if is_incremental() %}
  WHERE settlement_date >= {{ phase27_incremental_start_date('business_date') }}
  {% endif %}
  GROUP BY 1,2
), keys AS (
  SELECT business_date, currency FROM completed_transactions
  UNION DISTINCT SELECT business_date, currency FROM refunds
  UNION DISTINCT SELECT business_date, currency FROM reversals
  UNION DISTINCT SELECT business_date, currency FROM settlements
)
SELECT k.business_date, k.currency,
       COALESCE(t.transaction_count,0) AS transaction_count,
       COALESCE(t.transaction_amount_minor,0) AS transaction_amount_minor,
       COALESCE(rf.refund_count,0) AS refund_count,
       COALESCE(rf.refund_amount_minor,0) AS refund_amount_minor,
       COALESCE(rv.reversal_count,0) AS reversal_count,
       COALESCE(rv.reversal_amount_minor,0) AS reversal_amount_minor,
       COALESCE(st.settlement_item_count,0) AS settlement_item_count,
       COALESCE(st.settlement_net_amount_minor,0) AS settlement_net_amount_minor
FROM keys k
LEFT JOIN completed_transactions t USING (business_date, currency)
LEFT JOIN refunds rf USING (business_date, currency)
LEFT JOIN reversals rv USING (business_date, currency)
LEFT JOIN settlements st USING (business_date, currency)
