resource "google_bigquery_table" "pipeline_run" {
  count = var.enable_phase16_observability ? 1 : 0

  project             = var.project_id
  dataset_id          = google_bigquery_dataset.audit[0].dataset_id
  table_id            = "pipeline_run"
  deletion_protection = true

  time_partitioning {
    type  = "DAY"
    field = "observed_at"
  }

  clustering = ["status", "sla_status", "is_controlled_test"]

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "audit"
    purpose             = "pipeline-observability"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }

  schema = jsonencode([
    { name = "run_id", type = "STRING", mode = "REQUIRED" },
    { name = "start_time", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "end_time", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "status", type = "STRING", mode = "REQUIRED" },
    { name = "rows_received", type = "INTEGER", mode = "REQUIRED" },
    { name = "rows_loaded", type = "INTEGER", mode = "REQUIRED" },
    { name = "rows_rejected", type = "INTEGER", mode = "REQUIRED" },
    { name = "dq_failures", type = "INTEGER", mode = "REQUIRED" },
    { name = "failed_step", type = "STRING", mode = "NULLABLE" },
    { name = "error_message", type = "STRING", mode = "NULLABLE" },
    { name = "retry_count", type = "INTEGER", mode = "REQUIRED" },
    { name = "duration_seconds", type = "FLOAT", mode = "REQUIRED" },
    { name = "sla_status", type = "STRING", mode = "REQUIRED" },
    { name = "bytes_processed", type = "INTEGER", mode = "REQUIRED" },
    { name = "bytes_billed", type = "INTEGER", mode = "REQUIRED" },
    { name = "estimated_cost_usd", type = "NUMERIC", mode = "NULLABLE" },
    { name = "is_controlled_test", type = "BOOLEAN", mode = "REQUIRED" },
    { name = "observed_at", type = "TIMESTAMP", mode = "REQUIRED" }
  ])
}

resource "google_bigquery_table" "pipeline_step" {
  count = var.enable_phase16_observability ? 1 : 0

  project             = var.project_id
  dataset_id          = google_bigquery_dataset.audit[0].dataset_id
  table_id            = "pipeline_step"
  deletion_protection = true

  time_partitioning {
    type  = "DAY"
    field = "observed_at"
  }

  clustering = ["step_name", "status", "sla_status"]

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "audit"
    purpose             = "pipeline-step-observability"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }

  schema = jsonencode([
    { name = "run_id", type = "STRING", mode = "REQUIRED" },
    { name = "step_name", type = "STRING", mode = "REQUIRED" },
    { name = "step_sequence", type = "INTEGER", mode = "REQUIRED" },
    { name = "start_time", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "end_time", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "status", type = "STRING", mode = "REQUIRED" },
    { name = "rows_input", type = "INTEGER", mode = "REQUIRED" },
    { name = "rows_output", type = "INTEGER", mode = "REQUIRED" },
    { name = "error_message", type = "STRING", mode = "NULLABLE" },
    { name = "retry_count", type = "INTEGER", mode = "REQUIRED" },
    { name = "duration_seconds", type = "FLOAT", mode = "REQUIRED" },
    { name = "sla_status", type = "STRING", mode = "REQUIRED" },
    { name = "is_controlled_test", type = "BOOLEAN", mode = "REQUIRED" },
    { name = "observed_at", type = "TIMESTAMP", mode = "REQUIRED" }
  ])
}

resource "google_bigquery_table" "incident" {
  count = var.enable_phase16_observability ? 1 : 0

  project             = var.project_id
  dataset_id          = google_bigquery_dataset.audit[0].dataset_id
  table_id            = "incident"
  deletion_protection = true

  time_partitioning {
    type  = "DAY"
    field = "detected_at"
  }

  clustering = ["status", "severity", "incident_type"]

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "audit"
    purpose             = "incident-lifecycle"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }

  schema = jsonencode([
    { name = "incident_event_id", type = "STRING", mode = "REQUIRED" },
    { name = "incident_id", type = "STRING", mode = "REQUIRED" },
    { name = "run_id", type = "STRING", mode = "REQUIRED" },
    { name = "incident_type", type = "STRING", mode = "REQUIRED" },
    { name = "severity", type = "STRING", mode = "REQUIRED" },
    { name = "status", type = "STRING", mode = "REQUIRED" },
    { name = "detected_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "resolved_at", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "failed_step", type = "STRING", mode = "NULLABLE" },
    { name = "root_cause", type = "STRING", mode = "NULLABLE" },
    { name = "resolution", type = "STRING", mode = "NULLABLE" },
    { name = "prevention", type = "STRING", mode = "NULLABLE" },
    { name = "is_controlled_test", type = "BOOLEAN", mode = "REQUIRED" }
  ])
}

resource "google_bigquery_table" "cost_metric" {
  count = var.enable_phase16_observability ? 1 : 0

  project                  = var.project_id
  dataset_id               = google_bigquery_dataset.audit[0].dataset_id
  table_id                 = "cost_metric"
  deletion_protection      = true
  require_partition_filter = var.phase16_cost_metric_require_partition_filter

  time_partitioning {
    type  = "DAY"
    field = "captured_at"
  }

  clustering = ["job_marker", "is_controlled_test"]

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "audit"
    purpose             = "cost-telemetry"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }

  schema = jsonencode([
    { name = "cost_metric_id", type = "STRING", mode = "REQUIRED" },
    { name = "run_id", type = "STRING", mode = "REQUIRED" },
    { name = "job_marker", type = "STRING", mode = "REQUIRED" },
    { name = "bytes_processed", type = "INTEGER", mode = "REQUIRED" },
    { name = "bytes_billed", type = "INTEGER", mode = "REQUIRED" },
    { name = "estimated_cost_usd", type = "NUMERIC", mode = "NULLABLE" },
    { name = "captured_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "is_controlled_test", type = "BOOLEAN", mode = "REQUIRED" }
  ])
}

resource "google_logging_metric" "phase16_sla_breach" {
  count       = var.enable_phase16_observability ? 1 : 0
  project     = var.project_id
  name        = var.phase16_sla_log_metric_name
  description = "Counts controlled Project 08 Phase 16 SLA breach log events."
  filter      = "logName=\"projects/${var.project_id}/logs/${var.phase16_observability_log_id}\" AND resource.type=\"global\" AND jsonPayload.phase=\"16\" AND jsonPayload.sla_status=\"BREACHED\""

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "Project 08 Phase 16 SLA Breaches"
  }
}

resource "google_monitoring_alert_policy" "phase16_sla_breach" {
  count        = var.enable_phase16_observability ? 1 : 0
  project      = var.project_id
  display_name = var.phase16_alert_policy_display_name
  combiner     = "OR"
  enabled      = true
  severity     = "WARNING"

  conditions {
    display_name = "Phase 16 structured log reports SLA breach"

    condition_matched_log {
      filter = "logName=\"projects/${var.project_id}/logs/${var.phase16_observability_log_id}\" AND resource.type=\"global\" AND jsonPayload.phase=\"16\" AND jsonPayload.sla_status=\"BREACHED\""
    }
  }

  alert_strategy {
    auto_close = "1800s"

    notification_rate_limit {
      period = "300s"
    }
  }

  documentation {
    mime_type = "text/markdown"
    subject   = "Project 08 Phase 16 SLA breach"
    content   = "Portfolio-safe observability alert. Inspect pipeline_run, pipeline_step, incident, DQ, and reconciliation evidence before recovery."
  }

  user_labels = {
    project = "project08"
    phase   = "16"
    scope   = "synthetic-only"
  }
}
