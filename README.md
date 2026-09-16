# BigQuery Enterprise Data Platform on Google Cloud

Production-oriented **Data Engineering** portfolio centered on **Google Cloud + BigQuery**, with SQL/dbt transformation, Terraform infrastructure, Python engineering utilities, Data Quality, reconciliation, security/governance, observability, and CI/CD.

> This is the **sanitized public portfolio edition**. It contains representative engineering code, synthetic/portfolio-safe datasets, infrastructure definitions, and publication-safe evidence. Raw company data, PII, credentials, confidential client metrics, private runtime artifacts, and the private working history are intentionally excluded.

## Recruiter / Hiring Manager Snapshot

**Core skills demonstrated:** `Google Cloud` · `BigQuery` · `SQL` · `dbt-bigquery` · `Terraform` · `Python` · `Data Modeling` · `Data Quality` · `Reconciliation` · `CI/CD` · `Security & Governance` · `Monitoring & Recovery`

This repository is designed to answer a practical hiring question: **“What Data Engineer responsibilities can this candidate demonstrate with inspectable evidence?”**

| Common Data Engineer expectation | Skills demonstrated | Inspectable evidence |
|---|---|---|
| Build a cloud data warehouse | GCP, BigQuery, GCS, RAW → STAGING → CORE → MART | [`terraform/phase07_bigquery.tf`](terraform/phase07_bigquery.tf), [`sql/staging/stg_orders.sql`](sql/staging/stg_orders.sql) |
| Write production-oriented SQL and data models | BigQuery SQL, dbt-bigquery, dimensional modeling, marts | [`dbt/models/marts/mart_commerce_daily.sql`](dbt/models/marts/mart_commerce_daily.sql), [`dbt/models/financial_marts/mart_reconciliation_daily.sql`](dbt/models/financial_marts/mart_reconciliation_daily.sql) |
| Build reliable incremental pipelines | Incremental processing, idempotency, late-arriving data, recovery | [`dbt/macros/phase11_incremental_window.sql`](dbt/macros/phase11_incremental_window.sql), [`sql/phase11/late_arriving_recovery.sql`](sql/phase11/late_arriving_recovery.sql), [`evidence/phase_11_incremental_runtime.json`](evidence/phase_11_incremental_runtime.json) |
| Enforce Data Quality and reconciliation | DQ rules, dbt tests, payment/control reconciliation | [`sql/audit/phase13_dq_rules.sql`](sql/audit/phase13_dq_rules.sql), [`evidence/phase_13_dq_runtime.json`](evidence/phase_13_dq_runtime.json), [`evidence/phase_14_reconciliation_runtime.json`](evidence/phase_14_reconciliation_runtime.json) |
| Optimize BigQuery workloads | Partitioning, clustering, query optimization, cost controls | [`evidence/phase_08_physical_design.json`](evidence/phase_08_physical_design.json), [`sql/phase18/wasteful_query_detection.sql`](sql/phase18/wasteful_query_detection.sql) |
| Manage infrastructure as code | Terraform / HCL, repeatable GCP/BigQuery provisioning | [`terraform/`](terraform/) |
| Secure and govern enterprise data | IAM/security patterns, governance, masking concepts, metadata/lineage | [`terraform/phase20_governance.tf`](terraform/phase20_governance.tf), [`terraform/phase21_security.tf`](terraform/phase21_security.tf), [`terraform/phase22_enterprise_security.tf`](terraform/phase22_enterprise_security.tf) |
| Monitor, diagnose, and recover | Observability, failure detection, troubleshooting, recovery evidence | [`terraform/phase16_observability.tf`](terraform/phase16_observability.tf), [`evidence/phase_16_observability_runtime.json`](evidence/phase_16_observability_runtime.json), [`evidence/phase_08_failure_recovery_runtime.json`](evidence/phase_08_failure_recovery_runtime.json) |
| Use Python for Data Engineering automation | Synthetic-data generation, privacy validation, validation utilities | [`src/generators/portfolio_safe_generator.py`](src/generators/portfolio_safe_generator.py), [`src/privacy/phase03_privacy_validator.py`](src/privacy/phase03_privacy_validator.py) |
| Apply engineering quality gates | GitHub Actions, automated validation, publication/privacy guard | [`.github/workflows/public-ci.yml`](.github/workflows/public-ci.yml), [`tools/publication_guard.py`](tools/publication_guard.py) |

## What this project demonstrates

- GCS-style landing and BigQuery **RAW → STAGING → CORE → MART** architecture
- **BigQuery SQL + dbt-bigquery** transformation and semantic modeling patterns
- Incremental MERGE, idempotency, late-arriving data, and schema evolution
- Partitioning, clustering, query optimization, and cost engineering
- Data Quality, payment reconciliation, and control-total patterns
- Monitoring, troubleshooting, failure/recovery, and operational evidence
- IAM/security, governance, masking concepts, metadata, and lineage
- Terraform infrastructure-as-code and CI/CD publication controls
- Synthetic financial-operations extension for transactions, payments, reversals, settlements, and reconciliation

## Verified engineering evidence

The canonical build was accepted through **32/32 Definition-of-Done gates**, **12/12 live runtime checks**, regression testing, and Hosted CI PASS. Evidence included here is curated for public review and contains no raw company or real banking data.

## Visual Engineering Evidence

These portfolio-safe screenshots summarize runtime, controls, recovery, security, and delivery evidence from the canonical build. They are visual entry points; the linked SQL, dbt, Terraform, JSON evidence, and CI logs remain the inspectable source evidence.

<table>
<tr><td><b>dbt-bigquery semantic runtime</b><br><sub>Models, tests, semantic contracts, zero drift.</sub><br><img src="docs/assets/screenshots/01_dbt_semantic_runtime.png" alt="dbt-bigquery semantic runtime evidence"></td><td><b>Incremental MERGE & late-arriving recovery</b><br><sub>MERGE, idempotency, lookback window, backfill.</sub><br><img src="docs/assets/screenshots/02_incremental_merge_runtime.png" alt="Incremental MERGE evidence"></td></tr>
<tr><td><b>Payment reconciliation</b><br><sub>Control totals, mismatch detection, recovery.</sub><br><img src="docs/assets/screenshots/03_payment_reconciliation.png" alt="Payment reconciliation evidence"></td><td><b>Operational observability</b><br><sub>Monitoring, SLA breach detection, incident lifecycle.</sub><br><img src="docs/assets/screenshots/04_operational_observability.png" alt="Operational observability evidence"></td></tr>
<tr><td><b>BigQuery performance engineering</b><br><sub>Partition pruning, column pruning, query-plan evidence.</sub><br><img src="docs/assets/screenshots/05_bigquery_performance.png" alt="BigQuery performance evidence"></td><td><b>BigQuery cost engineering</b><br><sub>Processed/billed bytes, guardrails, cost telemetry.</sub><br><img src="docs/assets/screenshots/06_bigquery_cost_engineering.png" alt="BigQuery cost engineering evidence"></td></tr>
<tr><td><b>Governance, metadata & lineage</b><br><sub>Classification, lineage paths, metadata validation.</sub><br><img src="docs/assets/screenshots/07_governance_metadata_lineage.png" alt="Governance metadata lineage evidence"></td><td><b>Enterprise security design</b><br><sub>Restricted services, private-access policy, failure recovery.</sub><br><img src="docs/assets/screenshots/08_enterprise_security.png" alt="Enterprise security evidence"></td></tr>
<tr><td><b>Failure / troubleshooting / recovery</b><br><sub>Break → detect → diagnose → recover → validate.</sub><br><img src="docs/assets/screenshots/09_failure_troubleshooting_recovery.png" alt="Failure recovery evidence"></td><td><b>Synthetic financial reporting mart</b><br><sub>Incremental marts, reconciliation controls, anomalies = 0.</sub><br><img src="docs/assets/screenshots/10_synthetic_financial_mart.png" alt="Synthetic financial mart evidence"></td></tr>
<tr><td><b>CI/CD quality gates</b><br><sub>Hosted CI, release blocking/recovery, Terraform validation.</sub><br><img src="docs/assets/screenshots/11_cicd.png" alt="CI CD evidence"></td><td><b>Final production acceptance</b><br><sub>Fresh runtime, full regression, zero drift, final controls.</sub><br><img src="docs/assets/screenshots/12_final_acceptance.png" alt="Final acceptance evidence"></td></tr>
</table>

> **Privacy boundary:** all screenshots shown here are sanitized/public-safe summaries. They exclude project IDs, bucket names, principals, credentials, private run IDs, raw company data, PII, row-level payloads, and real banking data.
## Architecture

```mermaid
flowchart LR
  A[Synthetic / Sanitized Sources] --> B[GCS Landing Pattern]
  B --> C[BigQuery RAW]
  C --> D[BigQuery STAGING]
  D --> E[BigQuery CORE]
  E --> F[BigQuery MART]
  E --> G[Synthetic Financial Ops]
  D --> H[Data Quality]
  E --> I[Reconciliation]
  F --> J[Reporting / Controls]
  K[dbt-bigquery] --> D
  K --> E
  K --> F
  L[Terraform] --> C
  L --> D
  L --> E
  L --> F
```

## Repository map

- `dbt/` — dbt-bigquery models and tests
- `sql/` — BigQuery/warehouse SQL patterns
- `terraform/` — BigQuery/GCP infrastructure definitions
- `src/` — synthetic generation, privacy, and validation utilities
- `data/` — synthetic / portfolio-safe datasets only
- `evidence/` — curated publication-safe verification evidence
- `tools/` — public-repository privacy guard

## Privacy and confidentiality

Business workflows may be inspired by real commerce operations, but this public repository does **not** publish raw company data, personal information, real phone/address/tax/bank values, credentials, local-only runtime evidence, or confidential client metrics. Financial/banking patterns are synthetic training extensions and are not presented as real banking experience.

## Portfolio purpose

The repository is optimized for technical review for **Data Engineer / GCP-BigQuery Data Engineer** roles. The goal is not to make one language look dominant; it is to make the actual engineering capabilities and their evidence easy to inspect.