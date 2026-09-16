SELECT business_date, currency, control_name, COUNT(*) AS row_count
FROM {{ ref('mart_reconciliation_daily') }}
GROUP BY 1,2,3
HAVING COUNT(*) != 1
