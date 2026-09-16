resource "google_access_context_manager_access_policy" "phase22" {
  count  = var.enable_phase22_enterprise_security ? 1 : 0
  parent = "organizations/${var.phase22_organization_id}"
  title  = "Project 08 Enterprise Security Design Lab"
}

resource "google_access_context_manager_access_level" "phase22_trusted" {
  count       = var.enable_phase22_enterprise_security ? 1 : 0
  parent      = google_access_context_manager_access_policy.phase22[0].name
  name        = "${google_access_context_manager_access_policy.phase22[0].name}/accessLevels/p08_trusted_enterprise_access"
  title       = "P08 trusted enterprise access"
  description = "Design-only access level. Synthetic CIDRs; not applied in personal Project 08."
  basic {
    combining_function = "AND"
    conditions {
      ip_subnetworks = var.phase22_trusted_cidrs
    }
  }
}

resource "google_access_context_manager_service_perimeter" "phase22" {
  count                     = var.enable_phase22_enterprise_security ? 1 : 0
  parent                    = google_access_context_manager_access_policy.phase22[0].name
  name                      = "${google_access_context_manager_access_policy.phase22[0].name}/servicePerimeters/p08_enterprise_data_perimeter"
  title                     = "P08 enterprise data perimeter"
  description               = "Design-only VPC Service Controls perimeter for BigQuery and GCS."
  perimeter_type            = "PERIMETER_TYPE_REGULAR"
  use_explicit_dry_run_spec = true

  spec {
    resources           = ["projects/${var.phase22_project_number}"]
    restricted_services = ["bigquery.googleapis.com", "storage.googleapis.com"]
    access_levels       = [google_access_context_manager_access_level.phase22_trusted[0].name]
    vpc_accessible_services {
      enable_restriction = true
      allowed_services   = ["bigquery.googleapis.com", "storage.googleapis.com"]
    }
  }
}
