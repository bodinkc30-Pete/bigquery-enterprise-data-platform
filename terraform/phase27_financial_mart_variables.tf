variable "enable_phase27_financial_mart" {
  description = "Create the persistent Phase 27 synthetic financial reporting mart dataset. Tables are owned by dbt-bigquery."
  type        = bool
  default     = false
}

variable "phase27_financial_mart_dataset_id" {
  description = "Phase 27 synthetic financial reporting/control mart dataset ID."
  type        = string
  default     = "financial_mart_synth"
}
