variable "enable_bigquery_raw_staging" {
  description = "Create Phase 7 BigQuery RAW and STAGING datasets."
  type        = bool
  default     = false
}

variable "bigquery_raw_dataset_id" {
  description = "Phase 7 RAW dataset ID."
  type        = string
  default     = "raw"
}

variable "bigquery_staging_dataset_id" {
  description = "Phase 7 STAGING dataset ID."
  type        = string
  default     = "staging"
}
