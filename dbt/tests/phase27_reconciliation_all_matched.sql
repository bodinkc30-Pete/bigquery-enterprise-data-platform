SELECT *
FROM {{ ref('mart_reconciliation_daily') }}
WHERE control_status != 'MATCHED'
   OR count_difference != 0
   OR amount_difference_minor != 0
