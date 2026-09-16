variable "enable_bigquery_core" {
  description = "Create Phase 8 BigQuery CORE dataset."
  type        = bool
  default     = false
}

variable "bigquery_core_dataset_id" {
  description = "Phase 8 CORE dataset ID."
  type        = string
  default     = "core"
}
