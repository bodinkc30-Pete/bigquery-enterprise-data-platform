resource "google_bigquery_dataset" "audit" {
  count = var.enable_bigquery_audit ? 1 : 0

  dataset_id                 = var.bigquery_audit_dataset_id
  project                    = var.project_id
  location                   = upper(var.region)
  friendly_name              = "Project 08 AUDIT"
  description                = "Data-quality audit records for Project 08 Phase 13."
  deletion_policy            = "PREVENT"
  delete_contents_on_destroy = false
  max_time_travel_hours      = 48

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "audit"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }
}

resource "google_bigquery_table" "dq_result" {
  count = var.enable_bigquery_audit ? 1 : 0

  project             = var.project_id
  dataset_id          = google_bigquery_dataset.audit[0].dataset_id
  table_id            = "dq_result"
  deletion_protection = true

  time_partitioning {
    type  = "DAY"
    field = "detected_at"
  }

  clustering = ["dq_dimension", "severity", "status"]

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "audit"
    purpose             = "data-quality"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }

  schema = jsonencode([
    { name = "rule_id", type = "STRING", mode = "REQUIRED" },
    { name = "dataset_name", type = "STRING", mode = "REQUIRED" },
    { name = "table_name", type = "STRING", mode = "REQUIRED" },
    { name = "column_name", type = "STRING", mode = "NULLABLE" },
    { name = "dq_dimension", type = "STRING", mode = "REQUIRED" },
    { name = "severity", type = "STRING", mode = "REQUIRED" },
    { name = "observed_value", type = "STRING", mode = "NULLABLE" },
    { name = "expected_condition", type = "STRING", mode = "REQUIRED" },
    { name = "affected_rows", type = "INTEGER", mode = "REQUIRED" },
    { name = "run_id", type = "STRING", mode = "REQUIRED" },
    { name = "detected_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "status", type = "STRING", mode = "REQUIRED" },
    { name = "resolution", type = "STRING", mode = "NULLABLE" },
    { name = "is_controlled_test", type = "BOOLEAN", mode = "REQUIRED" }
  ])
}
