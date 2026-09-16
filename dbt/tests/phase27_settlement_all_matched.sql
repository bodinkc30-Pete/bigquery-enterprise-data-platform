SELECT *
FROM {{ ref('mart_settlement_daily') }}
WHERE control_status != 'MATCHED'
   OR item_count_difference != 0
   OR net_amount_difference_minor != 0
