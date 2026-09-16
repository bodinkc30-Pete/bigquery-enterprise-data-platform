SELECT business_date, currency, transaction_status, COUNT(*) AS row_count
FROM {{ ref('mart_transaction_status_daily') }}
GROUP BY 1,2,3
HAVING COUNT(*) != 1
