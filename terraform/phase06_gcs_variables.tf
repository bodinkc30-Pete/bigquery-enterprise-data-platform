variable "enable_gcs_landing_zone" {
  description = "Create the persistent Phase 6 GCS landing-zone bucket."
  type        = bool
  default     = false
}

variable "gcs_noncurrent_version_retention_days" {
  description = "Days to retain noncurrent object versions before lifecycle deletion."
  type        = number
  default     = 7

  validation {
    condition     = var.gcs_noncurrent_version_retention_days >= 1
    error_message = "Noncurrent-version retention must be at least 1 day."
  }
}
