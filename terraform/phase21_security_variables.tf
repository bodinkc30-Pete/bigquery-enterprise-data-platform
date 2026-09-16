variable "enable_phase21_security" {
  description = "Enable Project 08 Phase 21 IAM and BigQuery data-security lab resources."
  type        = bool
  default     = false
}

variable "phase21_operator_email" {
  description = "Private operator user email allowed to impersonate only Phase 21 lab identities."
  type        = string
  sensitive   = true
  default     = ""
}

variable "phase21_security_dataset_id" {
  description = "Portfolio-safe isolated dataset for Phase 21 row/column security tests."
  type        = string
  default     = "security_lab"
}

variable "phase21_security_event_require_partition_filter" {
  description = "Fail-safe toggle for requiring an observed_at partition filter on audit.security_event."
  type        = bool
  default     = true
}
