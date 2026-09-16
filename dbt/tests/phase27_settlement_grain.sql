SELECT settlement_date, currency, COUNT(*) AS row_count
FROM {{ ref('mart_settlement_daily') }}
GROUP BY 1,2
HAVING COUNT(*) != 1
