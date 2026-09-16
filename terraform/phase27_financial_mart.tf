resource "google_bigquery_dataset" "phase27_financial_mart" {
  count = var.enable_phase27_financial_mart ? 1 : 0

  dataset_id                 = var.phase27_financial_mart_dataset_id
  project                    = var.project_id
  location                   = upper(var.region)
  friendly_name              = "Project 08 Synthetic Financial Reporting Mart"
  description                = "Synthetic financial reporting and operational-control mart for Project 08 Phase 27. Tables are managed by dbt-bigquery. No real bank or company data."
  deletion_policy            = "PREVENT"
  delete_contents_on_destroy = false
  max_time_travel_hours      = 48

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "financial-mart"
    purpose             = "synthetic-financial-reporting"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }
}
