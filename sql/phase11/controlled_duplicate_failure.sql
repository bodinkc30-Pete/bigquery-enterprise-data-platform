CREATE TEMP TABLE phase11_target (
  record_id INT64,
  business_date DATE,
  amount INT64
);

INSERT INTO phase11_target VALUES
  (1, DATE '2026-08-10', 100);

CREATE TEMP TABLE phase11_incoming AS
SELECT 1 AS record_id, DATE '2026-08-10' AS business_date, 110 AS amount
UNION ALL
SELECT 1 AS record_id, DATE '2026-08-10' AS business_date, 120 AS amount;

ASSERT (
  SELECT COUNT(*)
  FROM (
    SELECT record_id
    FROM phase11_incoming
    GROUP BY record_id
    HAVING COUNT(*) > 1
  )
) = 0 AS 'PHASE11_DUPLICATE_SOURCE_KEY_DETECTED';
