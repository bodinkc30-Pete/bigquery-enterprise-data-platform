output "project_verified" {
  description = "True when Terraform resolves the configured Project 08 project."
  value       = data.google_project.current.project_id == var.project_id
}

output "baseline_service_account_count" {
  description = "Count of Phase 4 baseline service accounts verified by Terraform."
  value       = length(data.google_service_account.baseline)
}

output "validation_resource_enabled" {
  description = "Whether the temporary Phase 5 validation resource is enabled."
  value       = var.enable_validation_resource
}
