output "bigquery_raw_staging_enabled" {
  description = "Whether Phase 7 BigQuery RAW/STAGING datasets are enabled."
  value       = var.enable_bigquery_raw_staging
}

output "bigquery_raw_dataset_id" {
  description = "RAW dataset ID when Phase 7 is enabled."
  value       = var.enable_bigquery_raw_staging ? google_bigquery_dataset.raw[0].dataset_id : null
}

output "bigquery_staging_dataset_id" {
  description = "STAGING dataset ID when Phase 7 is enabled."
  value       = var.enable_bigquery_raw_staging ? google_bigquery_dataset.staging[0].dataset_id : null
}
