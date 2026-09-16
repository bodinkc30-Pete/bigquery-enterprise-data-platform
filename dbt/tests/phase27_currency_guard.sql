SELECT 'ops' AS model_name, currency FROM {{ ref('mart_financial_ops_daily') }} WHERE currency NOT IN ('THB','USD','SGD')
UNION ALL
SELECT 'status', currency FROM {{ ref('mart_transaction_status_daily') }} WHERE currency NOT IN ('THB','USD','SGD')
UNION ALL
SELECT 'settlement', currency FROM {{ ref('mart_settlement_daily') }} WHERE currency NOT IN ('THB','USD','SGD')
UNION ALL
SELECT 'reconciliation', currency FROM {{ ref('mart_reconciliation_daily') }} WHERE currency NOT IN ('THB','USD','SGD')
