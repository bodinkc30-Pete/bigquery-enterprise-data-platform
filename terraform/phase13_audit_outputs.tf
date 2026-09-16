output "bigquery_audit_enabled" {
  description = "Whether the Phase 13 AUDIT dataset is enabled."
  value       = var.enable_bigquery_audit
}

output "bigquery_audit_dataset_id" {
  description = "Phase 13 AUDIT dataset ID."
  value       = var.enable_bigquery_audit ? google_bigquery_dataset.audit[0].dataset_id : null
}

output "bigquery_dq_result_table_id" {
  description = "Phase 13 DQ result table ID."
  value       = var.enable_bigquery_audit ? google_bigquery_table.dq_result[0].table_id : null
}
