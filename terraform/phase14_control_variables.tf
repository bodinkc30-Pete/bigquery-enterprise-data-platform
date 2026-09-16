variable "enable_bigquery_control" {
  description = "Create Phase 14 BigQuery CONTROL dataset and reconciliation result table."
  type        = bool
  default     = false
}

variable "bigquery_control_dataset_id" {
  description = "Phase 14 CONTROL dataset ID."
  type        = string
  default     = "control"
}
