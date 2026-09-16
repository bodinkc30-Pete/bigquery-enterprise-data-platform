resource "google_bigquery_dataset" "mart" {
  count = var.enable_bigquery_mart ? 1 : 0

  dataset_id                 = var.bigquery_mart_dataset_id
  project                    = var.project_id
  location                   = upper(var.region)
  friendly_name              = "Project 08 MART"
  description                = "Business-facing commerce, marketing, creator, and payment marts for Project 08 Phase 10."
  deletion_policy            = "PREVENT"
  delete_contents_on_destroy = false
  max_time_travel_hours      = 48

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "mart"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }
}
