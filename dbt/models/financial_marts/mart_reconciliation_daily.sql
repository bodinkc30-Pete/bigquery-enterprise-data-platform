WITH control AS (
  SELECT * FROM {{ source('financial_ops_synth', 'daily_control_totals') }}
  {% if is_incremental() %}
  WHERE business_date >= {{ phase27_incremental_start_date('business_date') }}
  {% endif %}
), tx AS (
  SELECT DATE(initiated_at) AS business_date, currency,
         COUNT(*) AS actual_count, SUM(transaction_amount_minor) AS actual_amount_minor
  FROM {{ source('financial_ops_synth', 'transactions') }}
  WHERE status = 'COMPLETED'
  {% if is_incremental() %}
    AND DATE(initiated_at) >= {{ phase27_incremental_start_date('business_date') }}
  {% endif %}
  GROUP BY 1,2
), refunds AS (
  SELECT DATE(requested_at) AS business_date, currency,
         COUNT(*) AS actual_count, SUM(refund_amount_minor) AS actual_amount_minor
  FROM {{ source('financial_ops_synth', 'refunds') }}
  {% if is_incremental() %}
  WHERE DATE(requested_at) >= {{ phase27_incremental_start_date('business_date') }}
  {% endif %}
  GROUP BY 1,2
), reversals AS (
  SELECT DATE(created_at) AS business_date, currency,
         COUNT(*) AS actual_count, SUM(reversal_amount_minor) AS actual_amount_minor
  FROM {{ source('financial_ops_synth', 'reversals') }}
  {% if is_incremental() %}
  WHERE DATE(created_at) >= {{ phase27_incremental_start_date('business_date') }}
  {% endif %}
  GROUP BY 1,2
), settlements AS (
  SELECT settlement_date AS business_date, currency,
         COUNT(*) AS actual_count, SUM(net_amount_minor) AS actual_amount_minor
  FROM {{ source('financial_ops_synth', 'settlement_items') }}
  {% if is_incremental() %}
  WHERE settlement_date >= {{ phase27_incremental_start_date('business_date') }}
  {% endif %}
  GROUP BY 1,2
), batch AS (
  SELECT settlement_date AS business_date, currency,
         SUM(item_count) AS expected_count, SUM(net_amount_minor) AS expected_amount_minor
  FROM {{ source('financial_ops_synth', 'settlement_batches') }}
  {% if is_incremental() %}
  WHERE settlement_date >= {{ phase27_incremental_start_date('business_date') }}
  {% endif %}
  GROUP BY 1,2
), item AS (
  SELECT settlement_date AS business_date, currency,
         COUNT(*) AS actual_count, SUM(net_amount_minor) AS actual_amount_minor
  FROM {{ source('financial_ops_synth', 'settlement_items') }}
  {% if is_incremental() %}
  WHERE settlement_date >= {{ phase27_incremental_start_date('business_date') }}
  {% endif %}
  GROUP BY 1,2
), mart_grain AS (
  SELECT business_date, currency, COUNT(*) AS actual_count
  FROM {{ ref('mart_financial_ops_daily') }}
  {% if is_incremental() %}
  WHERE business_date >= {{ phase27_incremental_start_date('business_date') }}
  {% endif %}
  GROUP BY 1,2
), controls AS (
  SELECT c.business_date, c.currency, 'FIN_REC_001' AS control_name,
         c.transaction_count AS expected_count, COALESCE(t.actual_count,0) AS actual_count,
         COALESCE(t.actual_count,0) - c.transaction_count AS count_difference,
         c.transaction_amount_minor AS expected_amount_minor,
         COALESCE(t.actual_amount_minor,0) AS actual_amount_minor,
         COALESCE(t.actual_amount_minor,0) - c.transaction_amount_minor AS amount_difference_minor
  FROM control c LEFT JOIN tx t USING (business_date,currency)

  UNION ALL
  SELECT c.business_date, c.currency, 'FIN_REC_002',
         c.refund_count, COALESCE(r.actual_count,0), COALESCE(r.actual_count,0)-c.refund_count,
         c.refund_amount_minor, COALESCE(r.actual_amount_minor,0),
         COALESCE(r.actual_amount_minor,0)-c.refund_amount_minor
  FROM control c LEFT JOIN refunds r USING (business_date,currency)

  UNION ALL
  SELECT c.business_date, c.currency, 'FIN_REC_003',
         c.reversal_count, COALESCE(r.actual_count,0), COALESCE(r.actual_count,0)-c.reversal_count,
         c.reversal_amount_minor, COALESCE(r.actual_amount_minor,0),
         COALESCE(r.actual_amount_minor,0)-c.reversal_amount_minor
  FROM control c LEFT JOIN reversals r USING (business_date,currency)

  UNION ALL
  SELECT c.business_date, c.currency, 'FIN_REC_004',
         c.settlement_item_count, COALESCE(s.actual_count,0),
         COALESCE(s.actual_count,0)-c.settlement_item_count,
         c.settlement_net_amount_minor, COALESCE(s.actual_amount_minor,0),
         COALESCE(s.actual_amount_minor,0)-c.settlement_net_amount_minor
  FROM control c LEFT JOIN settlements s USING (business_date,currency)
  UNION ALL
  SELECT b.business_date, b.currency, 'FIN_REC_005',
         b.expected_count, COALESCE(i.actual_count,0),
         COALESCE(i.actual_count,0)-b.expected_count,
         b.expected_amount_minor, COALESCE(i.actual_amount_minor,0),
         COALESCE(i.actual_amount_minor,0)-b.expected_amount_minor
  FROM batch b LEFT JOIN item i USING (business_date,currency)

  UNION ALL
  SELECT m.business_date, m.currency, 'FIN_REC_006',
         1, m.actual_count, m.actual_count-1,
         0,
         CASE WHEN m.currency IN ('THB','USD','SGD') THEN 0 ELSE 1 END,
         CASE WHEN m.currency IN ('THB','USD','SGD') THEN 0 ELSE 1 END
  FROM mart_grain m
)
SELECT business_date, currency, control_name,
       expected_count, actual_count, count_difference,
       expected_amount_minor, actual_amount_minor, amount_difference_minor,
       CASE WHEN count_difference = 0 AND amount_difference_minor = 0
            THEN 'MATCHED' ELSE 'MISMATCHED' END AS control_status
FROM controls
