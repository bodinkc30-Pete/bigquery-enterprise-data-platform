variable "enable_bigquery_mart" {
  description = "Create Phase 10 BigQuery MART dataset."
  type        = bool
  default     = false
}

variable "bigquery_mart_dataset_id" {
  description = "Phase 10 MART dataset ID."
  type        = string
  default     = "mart"
}
