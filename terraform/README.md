# Project 08 Terraform Foundation

Phase 5 establishes a safe Terraform baseline for Project 08.

## Scope

Terraform reads and verifies the existing Phase 4 GCP project and four baseline service accounts. It does not manage or destroy those persistent Phase 4 resources.

A temporary service account (`sa-tf-p05-validation`) is available behind `enable_validation_resource=true` only to prove real `plan -> apply -> verify -> destroy` behavior. The normal/default state keeps this resource disabled.

Phase 5 intentionally creates no GCS bucket and no BigQuery dataset/table. Those belong to Phases 6 and 7.

## Files

- `versions.tf` - Terraform and Google Provider constraints
- `providers.tf` - Google Provider configuration
- `variables.tf` - project/region/baseline inputs
- `main.tf` - read-only baseline checks + temporary validation resource
- `outputs.tf` - non-sensitive validation outputs
- `terraform.tfvars.example` - public-safe example
- `.terraform.lock.hcl` - committed provider lock file

Real project values live in `terraform.tfvars`, which is gitignored.
