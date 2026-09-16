locals {
  phase15_required_services = toset([
    "composer.googleapis.com",
    "compute.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "storage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicedirectory.googleapis.com",
    "pubsub.googleapis.com",
    "sqladmin.googleapis.com",
    "bigquery.googleapis.com",
  ])

  phase15_project_roles = toset([
    "roles/composer.worker",
    "roles/bigquery.jobUser",
  ])

  phase15_read_datasets = {
    core    = var.bigquery_core_dataset_id
    mart    = var.bigquery_mart_dataset_id
    audit   = var.bigquery_audit_dataset_id
    control = var.bigquery_control_dataset_id
  }
}
resource "google_project_service" "phase15_required" {
  for_each = var.enable_composer_foundation ? local.phase15_required_services : toset([])

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}

resource "google_project_iam_member" "phase15_composer_project_roles" {
  for_each = var.enable_composer_foundation ? local.phase15_project_roles : toset([])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${data.google_service_account.baseline["sa-composer"].email}"

  depends_on = [google_project_service.phase15_required]
}

resource "google_bigquery_dataset_iam_member" "phase15_composer_readers" {
  for_each = var.enable_composer_foundation ? local.phase15_read_datasets : {}

  project    = var.project_id
  dataset_id = each.value
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${data.google_service_account.baseline["sa-composer"].email}"
}
resource "google_composer_environment" "phase15" {
  count = var.enable_composer_environment ? 1 : 0

  name    = var.composer_environment_name
  region  = var.region
  project = var.project_id

  labels = {
    project             = "project08"
    environment         = var.environment
    phase               = "15"
    purpose             = "managed-airflow-proof"
    data_classification = "synthetic-only"
    lifecycle           = "ephemeral"
    managed_by          = "terraform"
  }

  config {
    environment_size = "ENVIRONMENT_SIZE_SMALL"

    software_config {
      image_version = var.composer_image_version
    }

    node_config {
      service_account = data.google_service_account.baseline["sa-composer"].email
    }
    workloads_config {
      scheduler {
        count      = 1
        cpu        = 0.5
        memory_gb  = 2.5
        storage_gb = 2
      }

      dag_processor {
        count      = 1
        cpu        = 0.5
        memory_gb  = 2
        storage_gb = 1
      }

      web_server {
        cpu        = 1
        memory_gb  = 2.5
        storage_gb = 2
      }

      worker {
        cpu        = 0.5
        memory_gb  = 2
        storage_gb = 2
        min_count  = 1
        max_count  = 1
      }
    }
  }

  depends_on = [
    google_project_service.phase15_required,
    google_project_iam_member.phase15_composer_project_roles,
    google_service_account_iam_member.phase15_composer_service_agent_extension,
    google_bigquery_dataset_iam_member.phase15_composer_readers,
  ]
}

check "phase15_composer_image_when_enabled" {
  assert {
    condition = (
      !var.enable_composer_environment ||
      startswith(var.composer_image_version, "composer-3-airflow-")
    )
    error_message = "Phase 15 environment requires an explicit Managed Airflow Gen 3 image."
  }
}

resource "google_service_account_iam_member" "phase15_composer_service_agent_extension" {
  count = var.enable_composer_foundation ? 1 : 0

  service_account_id = data.google_service_account.baseline["sa-composer"].name
  role               = "roles/composer.ServiceAgentV2Ext"
  member             = "serviceAccount:service-${data.google_project.current.number}@cloudcomposer-accounts.iam.gserviceaccount.com"

  depends_on = [google_project_service.phase15_required]
}
