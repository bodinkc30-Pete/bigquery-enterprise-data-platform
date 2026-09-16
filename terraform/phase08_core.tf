resource "google_bigquery_dataset" "core" {
  count = var.enable_bigquery_core ? 1 : 0

  dataset_id                 = var.bigquery_core_dataset_id
  project                    = var.project_id
  location                   = upper(var.region)
  friendly_name              = "Project 08 CORE"
  description                = "Conformed dimensional and fact models for Project 08 Phase 8."
  deletion_policy            = "PREVENT"
  delete_contents_on_destroy = false
  max_time_travel_hours      = 48

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "core"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }
}
