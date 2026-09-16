variable "enable_bigquery_audit" {
  description = "Create Phase 13 BigQuery AUDIT dataset and DQ result table."
  type        = bool
  default     = false
}

variable "bigquery_audit_dataset_id" {
  description = "Phase 13 AUDIT dataset ID."
  type        = string
  default     = "audit"
}
