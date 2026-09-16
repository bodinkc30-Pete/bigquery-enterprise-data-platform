locals {
  phase21_required_services = toset([
    "datacatalog.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "iamcredentials.googleapis.com",
  ])
  phase21_identities = {
    analyst = "sa-p21-analyst"
    finance = "sa-p21-finance"
    viewer  = "sa-p21-viewer"
  }
}

resource "google_project_service" "phase21_required" {
  for_each           = var.enable_phase21_security ? local.phase21_required_services : toset([])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "phase21" {
  for_each     = var.enable_phase21_security ? local.phase21_identities : {}
  project      = var.project_id
  account_id   = each.value
  display_name = "Project 08 Phase 21 ${title(each.key)}"
  description  = "Keyless lab identity for Project 08 Phase 21 access-control proof."
}
resource "google_service_account_iam_member" "phase21_operator_impersonation" {
  for_each           = var.enable_phase21_security ? google_service_account.phase21 : {}
  service_account_id = each.value.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "user:${var.phase21_operator_email}"
}

resource "google_project_iam_member" "phase21_job_user" {
  for_each = var.enable_phase21_security ? google_service_account.phase21 : {}
  project  = var.project_id
  role     = "roles/bigquery.jobUser"
  member   = "serviceAccount:${each.value.email}"
}

resource "google_bigquery_dataset" "security_lab" {
  count                      = var.enable_phase21_security ? 1 : 0
  project                    = var.project_id
  dataset_id                 = var.phase21_security_dataset_id
  location                   = upper(var.region)
  friendly_name              = "Project 08 Phase 21 Security Lab"
  description                = "Portfolio-safe isolated row/column security and masking lab."
  deletion_policy            = "PREVENT"
  delete_contents_on_destroy = false
  max_time_travel_hours      = 48
  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "security-lab"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }
}
resource "google_bigquery_dataset_iam_member" "phase21_security_lab_viewers" {
  for_each   = var.enable_phase21_security ? google_service_account.phase21 : {}
  project    = var.project_id
  dataset_id = google_bigquery_dataset.security_lab[0].dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${each.value.email}"
}

resource "google_data_catalog_taxonomy" "phase21" {
  count                  = var.enable_phase21_security ? 1 : 0
  project                = var.project_id
  region                 = var.region
  display_name           = "Project 08 Phase 21 Security"
  description            = "Portfolio-safe policy taxonomy for Phase 21 column security."
  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]
  depends_on             = [google_project_service.phase21_required]
}

resource "google_data_catalog_policy_tag" "phase21_restricted_token" {
  count        = var.enable_phase21_security ? 1 : 0
  taxonomy     = google_data_catalog_taxonomy.phase21[0].id
  display_name = "restricted_synthetic_token"
  description  = "Synthetic sensitive token requiring fine-grained or masked access."
}

resource "google_data_catalog_policy_tag_iam_member" "phase21_finance_fine_grained" {
  count      = var.enable_phase21_security ? 1 : 0
  policy_tag = google_data_catalog_policy_tag.phase21_restricted_token[0].name
  role       = "roles/datacatalog.categoryFineGrainedReader"
  member     = "serviceAccount:${google_service_account.phase21["finance"].email}"
}

resource "google_bigquery_table" "phase21_secured_creator_payment" {
  count               = var.enable_phase21_security ? 1 : 0
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.security_lab[0].dataset_id
  table_id            = "secured_creator_payment"
  deletion_protection = true
  description         = "Synthetic creator-payment security lab with row policies and protected settlement token."

  time_partitioning {
    type  = "DAY"
    field = "post_date"
  }
  clustering = ["region_scope", "payment_status", "payment_cycle"]
  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "security-lab"
    data_classification = "restricted-synthetic-pii"
    managed_by          = "terraform"
  }
  schema = jsonencode([
    { name = "payment_id", type = "STRING", mode = "REQUIRED" },
    { name = "creator_key", type = "STRING", mode = "REQUIRED" },
    { name = "creator_token", type = "STRING", mode = "REQUIRED" },
    { name = "post_date", type = "DATE", mode = "REQUIRED" },
    { name = "payment_amount", type = "NUMERIC", mode = "REQUIRED" },
    {
      name       = "settlement_account_token", type = "STRING", mode = "REQUIRED",
      policyTags = { names = [google_data_catalog_policy_tag.phase21_restricted_token[0].name] }
    },
    { name = "payment_cycle", type = "STRING", mode = "REQUIRED" },
    { name = "payment_status", type = "STRING", mode = "REQUIRED" },
    { name = "region_scope", type = "STRING", mode = "REQUIRED" },
  ])

  depends_on = [
    google_bigquery_dataset_iam_member.phase21_security_lab_viewers,
    google_data_catalog_policy_tag_iam_member.phase21_finance_fine_grained,
  ]
}

resource "google_bigquery_row_access_policy" "phase21_th_scope" {
  count            = var.enable_phase21_security ? 1 : 0
  project          = var.project_id
  dataset_id       = google_bigquery_dataset.security_lab[0].dataset_id
  table_id         = google_bigquery_table.phase21_secured_creator_payment[0].table_id
  policy_id        = "th_scope"
  filter_predicate = "region_scope = 'TH'"
  grantees = [
    "serviceAccount:${google_service_account.phase21["analyst"].email}",
    "serviceAccount:${google_service_account.phase21["viewer"].email}",
  ]
}
resource "google_bigquery_row_access_policy" "phase21_finance_all" {
  count            = var.enable_phase21_security ? 1 : 0
  project          = var.project_id
  dataset_id       = google_bigquery_dataset.security_lab[0].dataset_id
  table_id         = google_bigquery_table.phase21_secured_creator_payment[0].table_id
  policy_id        = "finance_all"
  filter_predicate = "TRUE"
  grantees = [
    "serviceAccount:${google_service_account.phase21["finance"].email}",
  ]
}

resource "google_bigquery_table" "phase21_masked_creator_payment" {
  count               = var.enable_phase21_security ? 1 : 0
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.security_lab[0].dataset_id
  table_id            = "masked_creator_payment"
  deletion_protection = true
  description         = "Synthetic SQL-masked projection fallback for personal-project Phase 21 security lab."
  time_partitioning {
    type  = "DAY"
    field = "post_date"
  }
  clustering = ["region_scope", "payment_status", "payment_cycle"]
  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "security-lab"
    data_classification = "masked-synthetic-pii"
    managed_by          = "terraform"
  }
  schema = jsonencode([
    { name = "payment_id", type = "STRING", mode = "REQUIRED" },
    { name = "creator_key", type = "STRING", mode = "REQUIRED" },
    { name = "creator_token", type = "STRING", mode = "REQUIRED" },
    { name = "post_date", type = "DATE", mode = "REQUIRED" },
    { name = "payment_amount", type = "NUMERIC", mode = "REQUIRED" },
    { name = "settlement_account_masked", type = "STRING", mode = "REQUIRED" },
    { name = "payment_cycle", type = "STRING", mode = "REQUIRED" },
    { name = "payment_status", type = "STRING", mode = "REQUIRED" },
    { name = "region_scope", type = "STRING", mode = "REQUIRED" },
  ])
  depends_on = [google_bigquery_dataset_iam_member.phase21_security_lab_viewers]
}

resource "google_bigquery_row_access_policy" "phase21_masked_th_scope" {
  count            = var.enable_phase21_security ? 1 : 0
  project          = var.project_id
  dataset_id       = google_bigquery_dataset.security_lab[0].dataset_id
  table_id         = google_bigquery_table.phase21_masked_creator_payment[0].table_id
  policy_id        = "masked_th_scope"
  filter_predicate = "region_scope = 'TH'"
  grantees         = ["serviceAccount:${google_service_account.phase21["analyst"].email}"]
}
resource "google_bigquery_row_access_policy" "phase21_masked_finance_all" {
  count            = var.enable_phase21_security ? 1 : 0
  project          = var.project_id
  dataset_id       = google_bigquery_dataset.security_lab[0].dataset_id
  table_id         = google_bigquery_table.phase21_masked_creator_payment[0].table_id
  policy_id        = "masked_finance_all"
  filter_predicate = "TRUE"
  grantees         = ["serviceAccount:${google_service_account.phase21["finance"].email}"]
}

resource "google_bigquery_table" "phase21_security_event" {
  count                    = var.enable_phase21_security ? 1 : 0
  project                  = var.project_id
  dataset_id               = google_bigquery_dataset.audit[0].dataset_id
  table_id                 = "security_event"
  deletion_protection      = true
  require_partition_filter = var.phase21_security_event_require_partition_filter
  description              = "Phase 21 sanitized security-test event ledger."

  time_partitioning {
    type  = "DAY"
    field = "observed_at"
  }
  clustering = ["identity_role", "outcome", "test_name"]
  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "audit"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
    purpose             = "security-audit"
  }
  schema = jsonencode([
    { name = "event_id", type = "STRING", mode = "REQUIRED" },
    { name = "identity_role", type = "STRING", mode = "REQUIRED" },
    { name = "test_name", type = "STRING", mode = "REQUIRED" },
    { name = "resource_scope", type = "STRING", mode = "REQUIRED" },
    { name = "operation", type = "STRING", mode = "REQUIRED" },
    { name = "expected_outcome", type = "STRING", mode = "REQUIRED" },
    { name = "outcome", type = "STRING", mode = "REQUIRED" },
    { name = "error_class", type = "STRING", mode = "NULLABLE" },
    { name = "rows_visible", type = "INTEGER", mode = "NULLABLE" },
    { name = "masking_status", type = "STRING", mode = "NULLABLE" },
    { name = "bytes_processed", type = "INTEGER", mode = "NULLABLE" },
    { name = "observed_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "is_controlled_test", type = "BOOLEAN", mode = "REQUIRED" },
  ])
}
