output "bigquery_mart_enabled" {
  description = "Whether the Phase 10 MART dataset is enabled."
  value       = var.enable_bigquery_mart
}

output "bigquery_mart_dataset_id" {
  description = "Phase 10 MART dataset ID."
  value       = var.enable_bigquery_mart ? google_bigquery_dataset.mart[0].dataset_id : null
}
