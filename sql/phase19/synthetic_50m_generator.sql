-- Phase 19 deterministic synthetic scale generator.
-- Portfolio-safe only: no raw company rows or identifiers are used.
CREATE OR REPLACE TABLE `benchmark_p19.lab_a_unpartitioned`
OPTIONS(expiration_timestamp=TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 12 HOUR)) AS
WITH ids AS (
  SELECT CAST(a * 10000 + b AS INT64) AS row_id
  FROM UNNEST(GENERATE_ARRAY(0, 4999)) AS a
  CROSS JOIN UNNEST(GENERATE_ARRAY(1, 10000)) AS b
)
SELECT
  row_id,
  CONCAT('order_', CAST(IF(MOD(row_id,100)=0,row_id-1,row_id) AS STRING)) AS business_key,
  DATE_ADD(DATE '2025-01-01', INTERVAL MOD(row_id,365) DAY) AS event_date,
  DATE_ADD(DATE_ADD(DATE '2025-01-01', INTERVAL MOD(row_id,365) DAY), INTERVAL IF(MOD(row_id,33)=0,2,0) DAY) AS arrival_date,
  CASE WHEN MOD(row_id,100)<50 THEN 'SHOP' WHEN MOD(row_id,100)<80 THEN 'LIVE' WHEN MOD(row_id,100)<95 THEN 'ADS' ELSE 'OTHER' END AS channel,
  CASE WHEN MOD(row_id,100)<70 THEN 'COMPLETED' WHEN MOD(row_id,100)<82 THEN 'SHIPPED' WHEN MOD(row_id,100)<90 THEN 'CANCELLED' WHEN MOD(row_id,100)<95 THEN 'REFUNDED' ELSE 'PENDING' END AS order_status,
  1 + MOD(row_id,5) AS quantity,
  CAST(50 + MOD(row_id * 37,4950) AS NUMERIC) AS order_amount,
  IF(MOD(row_id,100) BETWEEN 90 AND 94,CAST(50 + MOD(row_id * 37,4950) AS NUMERIC),CAST(0 AS NUMERIC)) AS refund_amount,
  MOD(row_id,1000) AS creator_bucket,
  IF(MOD(row_id,50)=0,NULL,MOD(row_id,1000)) AS nullable_metric,
  MOD(row_id,33)=0 AS late_arriving,
  MOD(row_id,100)=0 AS duplicate_business_key
FROM ids;

-- Lab B and Lab C are derived from Lab A so all three physical designs contain identical rows.
CREATE OR REPLACE TABLE `benchmark_p19.lab_b_range_partitioned`
PARTITION BY RANGE_BUCKET(row_id, GENERATE_ARRAY(0, 51000000, 1000000))
OPTIONS(expiration_timestamp=TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 12 HOUR)) AS
SELECT * FROM `benchmark_p19.lab_a_unpartitioned`;

CREATE OR REPLACE TABLE `benchmark_p19.lab_c_partitioned_clustered`
PARTITION BY RANGE_BUCKET(row_id, GENERATE_ARRAY(0, 51000000, 1000000))
CLUSTER BY channel, order_status
OPTIONS(expiration_timestamp=TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 12 HOUR)) AS
SELECT * FROM `benchmark_p19.lab_a_unpartitioned`;
