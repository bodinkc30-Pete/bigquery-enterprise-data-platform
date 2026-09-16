-- Phase 18: portfolio-safe BigQuery cost telemetry / waste signals.
-- No project ID, job ID, query text, or business row values are selected.
WITH recent AS (
  SELECT
    creation_time,
    state,
    error_result,
    total_bytes_processed,
    total_bytes_billed,
    cache_hit,
    REGEXP_CONTAINS(UPPER(query), r'SELECT\s+\*') AS uses_select_star,
    REGEXP_CONTAINS(query, r'phase18_cost_') AS is_phase18_probe
  FROM `region-asia-southeast3`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
  WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
    AND job_type = 'QUERY'
)
SELECT
  creation_time,
  state,
  total_bytes_processed,
  total_bytes_billed,
  cache_hit,
  uses_select_star,
  SAFE_DIVIDE(total_bytes_billed, NULLIF(total_bytes_processed, 0)) AS billed_to_processed_ratio,
  error_result IS NOT NULL AS has_error
FROM recent
WHERE is_phase18_probe
ORDER BY creation_time DESC;
