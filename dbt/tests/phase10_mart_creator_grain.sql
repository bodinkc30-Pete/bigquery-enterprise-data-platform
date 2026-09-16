{{ config(tags=['phase10']) }}

SELECT
  date_key,
  creator_key,
  COUNT(*) AS row_count
FROM {{ ref('mart_creator_daily') }}
GROUP BY date_key, creator_key
HAVING COUNT(*) > 1
