WITH batch AS (
  SELECT settlement_date, currency,
         COUNT(*) AS batch_count,
         SUM(item_count) AS batch_item_count,
         SUM(gross_amount_minor) AS batch_gross_amount_minor,
         SUM(refund_amount_minor) AS batch_refund_amount_minor,
         SUM(reversal_amount_minor) AS batch_reversal_amount_minor,
         SUM(net_amount_minor) AS batch_net_amount_minor
  FROM {{ source('financial_ops_synth', 'settlement_batches') }}
  {% if is_incremental() %}
  WHERE settlement_date >= {{ phase27_incremental_start_date('settlement_date') }}
  {% endif %}
  GROUP BY 1,2
), items AS (
  SELECT settlement_date, currency,
         COUNT(*) AS item_count,
         SUM(gross_amount_minor) AS item_gross_amount_minor,
         SUM(refund_amount_minor) AS item_refund_amount_minor,
         SUM(reversal_amount_minor) AS item_reversal_amount_minor,
         SUM(net_amount_minor) AS item_net_amount_minor
  FROM {{ source('financial_ops_synth', 'settlement_items') }}
  {% if is_incremental() %}
  WHERE settlement_date >= {{ phase27_incremental_start_date('settlement_date') }}
  {% endif %}
  GROUP BY 1,2
)SELECT
  COALESCE(b.settlement_date, i.settlement_date) AS settlement_date,
  COALESCE(b.currency, i.currency) AS currency,
  COALESCE(b.batch_count, 0) AS batch_count,
  COALESCE(b.batch_item_count, 0) AS batch_item_count,
  COALESCE(i.item_count, 0) AS item_count,
  COALESCE(b.batch_gross_amount_minor, 0) AS batch_gross_amount_minor,
  COALESCE(i.item_gross_amount_minor, 0) AS item_gross_amount_minor,
  COALESCE(b.batch_refund_amount_minor, 0) AS batch_refund_amount_minor,
  COALESCE(i.item_refund_amount_minor, 0) AS item_refund_amount_minor,
  COALESCE(b.batch_reversal_amount_minor, 0) AS batch_reversal_amount_minor,
  COALESCE(i.item_reversal_amount_minor, 0) AS item_reversal_amount_minor,
  COALESCE(b.batch_net_amount_minor, 0) AS batch_net_amount_minor,
  COALESCE(i.item_net_amount_minor, 0) AS item_net_amount_minor,
  COALESCE(b.batch_item_count, 0) - COALESCE(i.item_count, 0) AS item_count_difference,
  COALESCE(b.batch_net_amount_minor, 0) - COALESCE(i.item_net_amount_minor, 0) AS net_amount_difference_minor,
  CASE WHEN COALESCE(b.batch_item_count, 0) = COALESCE(i.item_count, 0)
         AND COALESCE(b.batch_net_amount_minor, 0) = COALESCE(i.item_net_amount_minor, 0)
       THEN 'MATCHED' ELSE 'MISMATCHED' END AS control_status
FROM batch b
FULL OUTER JOIN items i USING (settlement_date, currency)
