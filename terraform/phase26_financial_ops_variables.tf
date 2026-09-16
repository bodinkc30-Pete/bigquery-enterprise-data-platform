variable "enable_phase26_financial_ops" {
  description = "Create the persistent Phase 26 synthetic financial-operations BigQuery dataset and tables."
  type        = bool
  default     = false
}

variable "phase26_financial_dataset_id" {
  description = "Phase 26 synthetic financial-operations dataset ID."
  type        = string
  default     = "financial_ops_synth"
}
