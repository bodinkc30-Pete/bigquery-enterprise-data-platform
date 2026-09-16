resource "google_bigquery_dataset" "raw" {
  count = var.enable_bigquery_raw_staging ? 1 : 0

  dataset_id                 = var.bigquery_raw_dataset_id
  project                    = var.project_id
  location                   = upper(var.region)
  friendly_name              = "Project 08 RAW"
  description                = "Portfolio-safe source-oriented landing tables for Project 08 Phase 7."
  deletion_policy            = "PREVENT"
  delete_contents_on_destroy = false
  max_time_travel_hours      = 48

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "raw"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }
}

resource "google_bigquery_dataset" "staging" {
  count = var.enable_bigquery_raw_staging ? 1 : 0

  dataset_id                 = var.bigquery_staging_dataset_id
  project                    = var.project_id
  location                   = upper(var.region)
  friendly_name              = "Project 08 STAGING"
  description                = "Typed and standardized staging tables for Project 08 Phase 7."
  deletion_policy            = "PREVENT"
  delete_contents_on_destroy = false
  max_time_travel_hours      = 48

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "staging"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }
}
