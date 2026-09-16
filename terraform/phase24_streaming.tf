locals {
  phase24_worker_roles = toset([
    "roles/dataflow.worker",
    "roles/pubsub.subscriber",
  ])
}

resource "google_project_service" "phase24_dataflow" {
  count              = var.enable_phase24_streaming_lab ? 1 : 0
  project            = var.project_id
  service            = "dataflow.googleapis.com"
  disable_on_destroy = true
}

resource "google_service_account" "phase24_stream" {
  count        = var.enable_phase24_streaming_lab ? 1 : 0
  project      = var.project_id
  account_id   = "sa-p24-stream"
  display_name = "Project 08 Phase 24 Streaming Worker"
}

resource "google_project_iam_member" "phase24_worker_roles" {
  for_each = var.enable_phase24_streaming_lab ? local.phase24_worker_roles : toset([])
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.phase24_stream[0].email}"
}
resource "google_service_account_iam_member" "phase24_operator_act_as" {
  count              = var.enable_phase24_streaming_lab && var.phase24_operator_email != "" ? 1 : 0
  service_account_id = google_service_account.phase24_stream[0].name
  role               = "roles/iam.serviceAccountUser"
  member             = "user:${var.phase24_operator_email}"
}

resource "google_storage_bucket_iam_member" "phase24_worker_temp_object_admin" {
  count  = var.enable_phase24_streaming_lab ? 1 : 0
  bucket = google_storage_bucket.landing[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.phase24_stream[0].email}"
}

resource "google_pubsub_topic" "phase24_events" {
  count   = var.enable_phase24_streaming_lab ? 1 : 0
  project = var.project_id
  name    = var.phase24_topic_name

  labels = {
    project     = "project08"
    phase       = "24"
    environment = var.environment
  }
}

resource "google_pubsub_subscription" "phase24_validation" {
  count                      = var.enable_phase24_streaming_lab ? 1 : 0
  project                    = var.project_id
  name                       = var.phase24_subscription_name
  topic                      = google_pubsub_topic.phase24_events[0].id
  ack_deadline_seconds       = 20
  message_retention_duration = "600s"
}
resource "google_pubsub_subscription" "phase24_dataflow" {
  count                      = var.enable_phase24_streaming_lab ? 1 : 0
  project                    = var.project_id
  name                       = var.phase24_dataflow_subscription_name
  topic                      = google_pubsub_topic.phase24_events[0].id
  ack_deadline_seconds       = 20
  message_retention_duration = "600s"
}

resource "google_bigquery_dataset_iam_member" "phase24_worker_control_editor" {
  count      = var.enable_phase24_streaming_lab ? 1 : 0
  project    = var.project_id
  dataset_id = var.bigquery_control_dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.phase24_stream[0].email}"
}

resource "google_bigquery_table" "phase24_stream_events" {
  count               = var.enable_phase24_streaming_lab ? 1 : 0
  project             = var.project_id
  dataset_id          = var.bigquery_control_dataset_id
  table_id            = "phase24_stream_events"
  deletion_protection = false

  time_partitioning {
    type  = "DAY"
    field = "event_ts"
  }

  clustering = ["event_type", "entity_id"]
  labels = {
    project = "project08"
    phase   = "24"
    source  = "synthetic"
  }
  schema = jsonencode([
    { name = "event_id", type = "STRING", mode = "REQUIRED" },
    { name = "event_type", type = "STRING", mode = "REQUIRED" },
    { name = "entity_id", type = "STRING", mode = "REQUIRED" },
    { name = "event_ts", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "publish_ts", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "amount", type = "NUMERIC", mode = "NULLABLE" },
    { name = "sequence_no", type = "INTEGER", mode = "REQUIRED" }
  ])

  depends_on = [
    google_project_service.phase24_dataflow,
    google_bigquery_dataset_iam_member.phase24_worker_control_editor,
  ]
}

resource "google_pubsub_topic_iam_member" "phase24_worker_topic_viewer" {
  count = var.enable_phase24_streaming_lab ? 1 : 0

  project = var.project_id
  topic   = google_pubsub_topic.phase24_events[0].name
  role    = "roles/pubsub.viewer"
  member  = "serviceAccount:${google_service_account.phase24_stream[0].email}"
}

resource "google_pubsub_subscription_iam_member" "phase24_worker_subscription_viewer" {
  count = var.enable_phase24_streaming_lab ? 1 : 0

  project      = var.project_id
  subscription = google_pubsub_subscription.phase24_dataflow[0].name
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${google_service_account.phase24_stream[0].email}"
}
