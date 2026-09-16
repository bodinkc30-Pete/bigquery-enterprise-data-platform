DECLARE watermark DATE;

CREATE TEMP TABLE phase11_target (
  record_id INT64,
  business_date DATE,
  amount INT64
);

INSERT INTO phase11_target VALUES
  (1, DATE '2026-08-10', 100),
  (2, DATE '2026-08-05', 200);

CREATE TEMP TABLE phase11_incoming AS
SELECT 1 AS record_id, DATE '2026-08-10' AS business_date, 110 AS amount
UNION ALL SELECT 3, DATE '2026-08-08', 300
UNION ALL SELECT 4, DATE '2026-07-01', 400;

SET watermark = (SELECT MAX(business_date) FROM phase11_target);

MERGE phase11_target AS t
USING (
  SELECT * FROM phase11_incoming
  WHERE business_date >= DATE_SUB(watermark, INTERVAL 7 DAY)
) AS s
ON t.record_id = s.record_id
WHEN MATCHED THEN UPDATE SET business_date = s.business_date, amount = s.amount
WHEN NOT MATCHED THEN INSERT (record_id, business_date, amount)
VALUES (s.record_id, s.business_date, s.amount);
ASSERT (SELECT COUNT(*) FROM phase11_target WHERE record_id = 3) = 1
  AS 'PHASE11_LATE_ROW_WITHIN_LOOKBACK_MISSING';
ASSERT (SELECT COUNT(*) FROM phase11_target WHERE record_id = 4) = 0
  AS 'PHASE11_OLD_ROW_SHOULD_REQUIRE_BACKFILL';

MERGE phase11_target AS t
USING (
  SELECT * FROM phase11_incoming
  WHERE business_date >= DATE_SUB(watermark, INTERVAL 7 DAY)
) AS s
ON t.record_id = s.record_id
WHEN MATCHED THEN UPDATE SET business_date = s.business_date, amount = s.amount
WHEN NOT MATCHED THEN INSERT (record_id, business_date, amount)
VALUES (s.record_id, s.business_date, s.amount);

ASSERT (SELECT COUNT(*) FROM phase11_target) = 3
  AS 'PHASE11_LOOKBACK_RERUN_NOT_IDEMPOTENT';
ASSERT (
  SELECT COUNT(*) FROM (
    SELECT record_id FROM phase11_target GROUP BY record_id HAVING COUNT(*) > 1
  )
) = 0 AS 'PHASE11_LOOKBACK_DUPLICATE_CREATED';
MERGE phase11_target AS t
USING (
  SELECT * FROM phase11_incoming
  WHERE business_date >= DATE '2026-07-01'
) AS s
ON t.record_id = s.record_id
WHEN MATCHED THEN UPDATE SET business_date = s.business_date, amount = s.amount
WHEN NOT MATCHED THEN INSERT (record_id, business_date, amount)
VALUES (s.record_id, s.business_date, s.amount);

ASSERT (SELECT COUNT(*) FROM phase11_target WHERE record_id = 4) = 1
  AS 'PHASE11_EXPLICIT_BACKFILL_FAILED';

MERGE phase11_target AS t
USING (
  SELECT * FROM phase11_incoming
  WHERE business_date >= DATE '2026-07-01'
) AS s
ON t.record_id = s.record_id
WHEN MATCHED THEN UPDATE SET business_date = s.business_date, amount = s.amount
WHEN NOT MATCHED THEN INSERT (record_id, business_date, amount)
VALUES (s.record_id, s.business_date, s.amount);

ASSERT (SELECT COUNT(*) FROM phase11_target) = 4
  AS 'PHASE11_BACKFILL_RERUN_NOT_IDEMPOTENT';
ASSERT (
  SELECT COUNT(*) FROM (
    SELECT record_id FROM phase11_target GROUP BY record_id HAVING COUNT(*) > 1
  )
) = 0 AS 'PHASE11_BACKFILL_DUPLICATE_CREATED';

SELECT
  COUNT(*) AS final_row_count,
  COUNTIF(record_id = 3) AS late_arriving_rows,
  COUNTIF(record_id = 4) AS explicit_backfill_rows,
  COUNT(*) - COUNT(DISTINCT record_id) AS duplicate_rows
FROM phase11_target;
