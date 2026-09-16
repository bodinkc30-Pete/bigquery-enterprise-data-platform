output "bigquery_control_enabled" {
  description = "Whether the Phase 14 CONTROL dataset is enabled."
  value       = var.enable_bigquery_control
}

output "bigquery_control_dataset_id" {
  description = "Phase 14 CONTROL dataset ID."
  value       = var.enable_bigquery_control ? google_bigquery_dataset.control[0].dataset_id : null
}

output "bigquery_reconciliation_result_table_id" {
  description = "Phase 14 reconciliation result table ID."
  value       = var.enable_bigquery_control ? google_bigquery_table.reconciliation_result[0].table_id : null
}
