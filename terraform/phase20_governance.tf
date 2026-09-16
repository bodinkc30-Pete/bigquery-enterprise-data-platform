resource "google_bigquery_table" "data_asset_registry" {
  count               = var.enable_phase20_governance ? 1 : 0
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.audit[0].dataset_id
  table_id            = "data_asset_registry"
  deletion_protection = true
  description         = "Project 08 governed data-asset registry for portfolio-safe BigQuery assets."

  time_partitioning {
    type  = "DAY"
    field = "updated_at"
  }

  clustering = ["layer", "classification", "status"]

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "audit"
    purpose             = "data-governance"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }
  schema = jsonencode([
    { name = "asset_id", type = "STRING", mode = "REQUIRED" },
    { name = "asset_type", type = "STRING", mode = "REQUIRED" },
    { name = "layer", type = "STRING", mode = "REQUIRED" },
    { name = "dataset_name", type = "STRING", mode = "NULLABLE" },
    { name = "asset_name", type = "STRING", mode = "REQUIRED" },
    { name = "business_owner", type = "STRING", mode = "REQUIRED" },
    { name = "technical_owner", type = "STRING", mode = "REQUIRED" },
    { name = "business_definition", type = "STRING", mode = "REQUIRED" },
    { name = "source_system", type = "STRING", mode = "REQUIRED" },
    { name = "destination", type = "STRING", mode = "REQUIRED" },
    { name = "classification", type = "STRING", mode = "REQUIRED" },
    { name = "pii_flag", type = "BOOLEAN", mode = "REQUIRED" },
    { name = "retention_days", type = "INTEGER", mode = "REQUIRED" },
    { name = "refresh_frequency", type = "STRING", mode = "REQUIRED" },
    { name = "refresh_sla_minutes", type = "INTEGER", mode = "REQUIRED" },
    { name = "dq_sla_minutes", type = "INTEGER", mode = "REQUIRED" },
    { name = "access_role", type = "STRING", mode = "REQUIRED" },
    { name = "lineage_status", type = "STRING", mode = "REQUIRED" },
    { name = "code_model_version", type = "STRING", mode = "REQUIRED" },
    { name = "status", type = "STRING", mode = "REQUIRED" },
    { name = "registered_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "updated_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "is_controlled_test", type = "BOOLEAN", mode = "REQUIRED" }
  ])
}
resource "google_bigquery_table" "column_governance" {
  count               = var.enable_phase20_governance ? 1 : 0
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.audit[0].dataset_id
  table_id            = "column_governance"
  deletion_protection = true
  description         = "Project 08 column-level governance classification metadata."

  time_partitioning {
    type  = "DAY"
    field = "observed_at"
  }

  clustering = ["classification", "asset_id", "governance_status"]

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "audit"
    purpose             = "column-governance"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }
  schema = jsonencode([
    { name = "column_governance_id", type = "STRING", mode = "REQUIRED" },
    { name = "asset_id", type = "STRING", mode = "REQUIRED" },
    { name = "dataset_name", type = "STRING", mode = "REQUIRED" },
    { name = "table_name", type = "STRING", mode = "REQUIRED" },
    { name = "column_name", type = "STRING", mode = "REQUIRED" },
    { name = "data_type", type = "STRING", mode = "REQUIRED" },
    { name = "classification", type = "STRING", mode = "REQUIRED" },
    { name = "pii_flag", type = "BOOLEAN", mode = "REQUIRED" },
    { name = "financial_flag", type = "BOOLEAN", mode = "REQUIRED" },
    { name = "masking_required", type = "BOOLEAN", mode = "REQUIRED" },
    { name = "approved_access_role", type = "STRING", mode = "REQUIRED" },
    { name = "classification_reason", type = "STRING", mode = "REQUIRED" },
    { name = "governance_status", type = "STRING", mode = "REQUIRED" },
    { name = "observed_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "is_controlled_test", type = "BOOLEAN", mode = "REQUIRED" }
  ])
}
resource "google_bigquery_table" "lineage_event" {
  count               = var.enable_phase20_governance ? 1 : 0
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.audit[0].dataset_id
  table_id            = "lineage_event"
  deletion_protection = true
  description         = "Project 08 source-to-mart lineage event ledger derived from governed mappings and dbt manifest dependencies."

  time_partitioning {
    type  = "DAY"
    field = "observed_at"
  }

  clustering = ["source_asset_id", "target_asset_id", "status"]

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "audit"
    purpose             = "data-lineage"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }
  schema = jsonencode([
    { name = "lineage_event_id", type = "STRING", mode = "REQUIRED" },
    { name = "run_id", type = "STRING", mode = "REQUIRED" },
    { name = "source_asset_id", type = "STRING", mode = "REQUIRED" },
    { name = "target_asset_id", type = "STRING", mode = "REQUIRED" },
    { name = "transformation_type", type = "STRING", mode = "REQUIRED" },
    { name = "transformation_ref", type = "STRING", mode = "REQUIRED" },
    { name = "code_model_version", type = "STRING", mode = "REQUIRED" },
    { name = "status", type = "STRING", mode = "REQUIRED" },
    { name = "evidence_source", type = "STRING", mode = "REQUIRED" },
    { name = "observed_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "is_controlled_test", type = "BOOLEAN", mode = "REQUIRED" }
  ])
}
