SELECT business_date, currency, COUNT(*) AS row_count
FROM {{ ref('mart_financial_ops_daily') }}
GROUP BY 1,2
HAVING COUNT(*) != 1
