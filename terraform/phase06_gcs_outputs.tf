output "gcs_landing_zone_enabled" {
  description = "Whether the persistent Phase 6 GCS landing zone is enabled."
  value       = var.enable_gcs_landing_zone
}

output "gcs_landing_bucket_name" {
  description = "Landing bucket name; treat the real value as runtime metadata."
  value       = var.enable_gcs_landing_zone ? google_storage_bucket.landing[0].name : null
  sensitive   = true
}

output "gcs_landing_location" {
  description = "Landing bucket location."
  value       = var.enable_gcs_landing_zone ? google_storage_bucket.landing[0].location : null
}
