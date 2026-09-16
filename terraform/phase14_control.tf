resource "google_bigquery_dataset" "control" {
  count = var.enable_bigquery_control ? 1 : 0

  dataset_id                 = var.bigquery_control_dataset_id
  project                    = var.project_id
  location                   = upper(var.region)
  friendly_name              = "Project 08 CONTROL"
  description                = "Payment reconciliation control records for Project 08 Phase 14."
  deletion_policy            = "PREVENT"
  delete_contents_on_destroy = false
  max_time_travel_hours      = 48

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "control"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }
}

resource "google_bigquery_table" "reconciliation_result" {
  count = var.enable_bigquery_control ? 1 : 0

  project             = var.project_id
  dataset_id          = google_bigquery_dataset.control[0].dataset_id
  table_id            = "reconciliation_result"
  deletion_protection = true

  time_partitioning {
    type  = "DAY"
    field = "detected_at"
  }

  clustering = ["control_name", "status", "payment_cycle"]

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "control"
    purpose             = "payment-reconciliation"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }

  schema = jsonencode([
    { name = "reconciliation_id", type = "STRING", mode = "REQUIRED" },
    { name = "control_name", type = "STRING", mode = "REQUIRED" },
    { name = "business_date", type = "DATE", mode = "NULLABLE" },
    { name = "payment_cycle", type = "STRING", mode = "NULLABLE" },
    { name = "payment_status", type = "STRING", mode = "NULLABLE" },
    { name = "payment_type", type = "STRING", mode = "NULLABLE" },
    { name = "expected_count", type = "INTEGER", mode = "NULLABLE" },
    { name = "actual_count", type = "INTEGER", mode = "NULLABLE" },
    { name = "count_difference", type = "INTEGER", mode = "NULLABLE" },
    { name = "expected_amount", type = "NUMERIC", mode = "NULLABLE" },
    { name = "actual_amount", type = "NUMERIC", mode = "NULLABLE" },
    { name = "amount_difference", type = "NUMERIC", mode = "NULLABLE" },
    { name = "tolerance_amount", type = "NUMERIC", mode = "REQUIRED" },
    { name = "status", type = "STRING", mode = "REQUIRED" },
    { name = "incident_status", type = "STRING", mode = "REQUIRED" },
    { name = "run_id", type = "STRING", mode = "REQUIRED" },
    { name = "detected_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "resolution", type = "STRING", mode = "NULLABLE" },
    { name = "is_controlled_test", type = "BOOLEAN", mode = "REQUIRED" }
  ])
}
