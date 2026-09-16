variable "project_id" {
  description = "Existing Project 08 GCP project ID. Keep real value in local tfvars only."
  type        = string
}

variable "region" {
  description = "Primary GCP region baseline."
  type        = string
  default     = "asia-southeast3"
}

variable "environment" {
  description = "Portfolio environment label."
  type        = string
  default     = "portfolio"
}

variable "baseline_service_accounts" {
  description = "Phase 4 baseline service account IDs that Terraform must verify."
  type        = set(string)
  default = [
    "sa-data-pipeline",
    "sa-dbt",
    "sa-composer",
    "sa-cicd",
  ]
}

variable "enable_validation_resource" {
  description = "Create the temporary Phase 5 Terraform validation service account."
  type        = bool
  default     = false
}
