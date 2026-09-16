data "google_project" "current" {
  project_id = var.project_id
}

data "google_service_account" "baseline" {
  for_each = var.baseline_service_accounts

  account_id = each.value
  project    = var.project_id
}

resource "google_service_account" "phase05_validation" {
  count = var.enable_validation_resource ? 1 : 0

  account_id   = "sa-tf-p05-validation"
  display_name = "Phase 05 Terraform Validation"
  description  = "Temporary validation resource for Project 08 Phase 5; destroyed after proof."
  project      = var.project_id
}

check "project_resolves" {
  assert {
    condition     = data.google_project.current.project_id == var.project_id && data.google_project.current.number != null
    error_message = "Project 08 must resolve successfully before Terraform foundation validation."
  }
}

check "phase04_service_accounts_exist" {
  assert {
    condition     = length(data.google_service_account.baseline) == 4
    error_message = "Expected all four Phase 4 baseline service accounts."
  }
}
