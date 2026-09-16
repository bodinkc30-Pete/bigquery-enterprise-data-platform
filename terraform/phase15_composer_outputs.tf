output "phase15_composer_foundation_enabled" {
  description = "Whether Phase 15 API/IAM foundation is managed."
  value       = var.enable_composer_foundation
}

output "phase15_composer_environment_enabled" {
  description = "Whether the ephemeral Phase 15 Managed Airflow environment is currently enabled."
  value       = var.enable_composer_environment
}

output "phase15_composer_environment_name" {
  description = "Ephemeral Phase 15 environment name when present."
  value       = var.enable_composer_environment ? google_composer_environment.phase15[0].name : null
}

output "phase15_composer_image_version" {
  description = "Explicit Composer 3 image selected for the runtime proof."
  value       = var.composer_image_version
}
