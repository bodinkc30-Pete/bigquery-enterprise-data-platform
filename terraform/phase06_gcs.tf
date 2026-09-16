resource "google_storage_bucket" "landing" {
  count = var.enable_gcs_landing_zone ? 1 : 0

  name          = "p08-${data.google_project.current.number}-landing"
  project       = var.project_id
  location      = var.region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "landing"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      days_since_noncurrent_time = var.gcs_noncurrent_version_retention_days
      with_state                 = "ARCHIVED"
    }
  }

  soft_delete_policy {
    retention_duration_seconds = 0
  }
}

resource "google_storage_bucket_iam_member" "pipeline_object_creator" {
  count = var.enable_gcs_landing_zone ? 1 : 0

  bucket = google_storage_bucket.landing[0].name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${data.google_service_account.baseline["sa-data-pipeline"].email}"
}
