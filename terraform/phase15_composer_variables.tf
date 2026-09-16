variable "enable_composer_foundation" {
  description = "Manage Phase 15 required APIs and least-privilege Composer IAM bindings."
  type        = bool
  default     = false
}

variable "enable_composer_environment" {
  description = "Create the ephemeral Phase 15 Managed Airflow environment only during runtime proof."
  type        = bool
  default     = false
}

variable "composer_environment_name" {
  description = "Ephemeral Phase 15 Managed Airflow environment name."
  type        = string
  default     = "p08-composer-p15"
}

variable "composer_image_version" {
  description = "Explicit Managed Airflow Gen 3 image selected from the live supported image list."
  type        = string
  default     = ""
}
