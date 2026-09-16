output "bigquery_core_enabled" {
  description = "Whether the Phase 8 CORE dataset is enabled."
  value       = var.enable_bigquery_core
}

output "bigquery_core_dataset_id" {
  description = "Phase 8 CORE dataset ID."
  value       = var.enable_bigquery_core ? google_bigquery_dataset.core[0].dataset_id : null
}
