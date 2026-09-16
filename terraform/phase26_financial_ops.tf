resource "google_bigquery_dataset" "phase26_financial" {
  count = var.enable_phase26_financial_ops ? 1 : 0

  dataset_id                 = var.phase26_financial_dataset_id
  project                    = var.project_id
  location                   = upper(var.region)
  friendly_name              = "Project 08 Synthetic Financial Operations"
  description                = "Fully synthetic financial-operations simulation for Project 08 Phase 26. No real bank or company data."
  deletion_policy            = "PREVENT"
  delete_contents_on_destroy = false
  max_time_travel_hours      = 48

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "financial-ops"
    purpose             = "synthetic-financial-operations"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }
}

locals {
  phase26_financial_tables = {
    customers = {
      partition_field = null
      clustering      = ["risk_tier", "segment", "country_code"]
      schema = [
        { name = "customer_id", type = "STRING", mode = "REQUIRED" },
        { name = "customer_token", type = "STRING", mode = "REQUIRED" },
        { name = "risk_tier", type = "STRING", mode = "REQUIRED" },
        { name = "segment", type = "STRING", mode = "REQUIRED" },
        { name = "country_code", type = "STRING", mode = "REQUIRED" },
        { name = "created_at", type = "TIMESTAMP", mode = "REQUIRED" },
      ]
    }
    accounts = {
      partition_field = null
      clustering      = ["customer_id", "currency", "account_status"]
      schema = [
        { name = "account_id", type = "STRING", mode = "REQUIRED" },
        { name = "customer_id", type = "STRING", mode = "REQUIRED" },
        { name = "account_token", type = "STRING", mode = "REQUIRED" },
        { name = "currency", type = "STRING", mode = "REQUIRED" },
        { name = "account_status", type = "STRING", mode = "REQUIRED" },
        { name = "opened_at", type = "TIMESTAMP", mode = "REQUIRED" },
      ]
    }
    merchants = {
      partition_field = null
      clustering      = ["settlement_currency", "merchant_category", "merchant_status"]
      schema = [
        { name = "merchant_id", type = "STRING", mode = "REQUIRED" },
        { name = "merchant_token", type = "STRING", mode = "REQUIRED" },
        { name = "merchant_category", type = "STRING", mode = "REQUIRED" },
        { name = "country_code", type = "STRING", mode = "REQUIRED" },
        { name = "settlement_currency", type = "STRING", mode = "REQUIRED" },
        { name = "merchant_status", type = "STRING", mode = "REQUIRED" },
      ]
    }
    transactions = {
      partition_field = "initiated_at"
      clustering      = ["account_id", "merchant_id", "status"]
      schema = [
        { name = "transaction_id", type = "STRING", mode = "REQUIRED" },
        { name = "account_id", type = "STRING", mode = "REQUIRED" },
        { name = "merchant_id", type = "STRING", mode = "REQUIRED" },
        { name = "idempotency_key", type = "STRING", mode = "REQUIRED" },
        { name = "currency", type = "STRING", mode = "REQUIRED" },
        { name = "transaction_amount_minor", type = "INTEGER", mode = "REQUIRED" },
        { name = "status", type = "STRING", mode = "REQUIRED" },
        { name = "initiated_at", type = "TIMESTAMP", mode = "REQUIRED" },
        { name = "completed_at", type = "TIMESTAMP", mode = "NULLABLE" },
      ]
    }
    payment_events = {
      partition_field = "event_time"
      clustering      = ["transaction_id", "event_type", "status"]
      schema = [
        { name = "payment_event_id", type = "STRING", mode = "REQUIRED" },
        { name = "transaction_id", type = "STRING", mode = "REQUIRED" },
        { name = "event_sequence", type = "INTEGER", mode = "REQUIRED" },
        { name = "event_type", type = "STRING", mode = "REQUIRED" },
        { name = "status", type = "STRING", mode = "REQUIRED" },
        { name = "currency", type = "STRING", mode = "REQUIRED" },
        { name = "event_amount_minor", type = "INTEGER", mode = "REQUIRED" },
        { name = "event_time", type = "TIMESTAMP", mode = "REQUIRED" },
      ]
    }
    refunds = {
      partition_field = "requested_at"
      clustering      = ["transaction_id", "currency", "status"]
      schema = [
        { name = "refund_id", type = "STRING", mode = "REQUIRED" },
        { name = "transaction_id", type = "STRING", mode = "REQUIRED" },
        { name = "currency", type = "STRING", mode = "REQUIRED" },
        { name = "refund_amount_minor", type = "INTEGER", mode = "REQUIRED" },
        { name = "status", type = "STRING", mode = "REQUIRED" },
        { name = "requested_at", type = "TIMESTAMP", mode = "REQUIRED" },
        { name = "completed_at", type = "TIMESTAMP", mode = "REQUIRED" },
      ]
    }
    reversals = {
      partition_field = "created_at"
      clustering      = ["transaction_id", "currency", "status"]
      schema = [
        { name = "reversal_id", type = "STRING", mode = "REQUIRED" },
        { name = "transaction_id", type = "STRING", mode = "REQUIRED" },
        { name = "currency", type = "STRING", mode = "REQUIRED" },
        { name = "reversal_amount_minor", type = "INTEGER", mode = "REQUIRED" },
        { name = "reason_code", type = "STRING", mode = "REQUIRED" },
        { name = "status", type = "STRING", mode = "REQUIRED" },
        { name = "created_at", type = "TIMESTAMP", mode = "REQUIRED" },
      ]
    }
    settlement_batches = {
      partition_field = "settlement_date"
      clustering      = ["currency", "batch_status"]
      schema = [
        { name = "settlement_batch_id", type = "STRING", mode = "REQUIRED" },
        { name = "settlement_date", type = "DATE", mode = "REQUIRED" },
        { name = "currency", type = "STRING", mode = "REQUIRED" },
        { name = "batch_status", type = "STRING", mode = "REQUIRED" },
        { name = "item_count", type = "INTEGER", mode = "REQUIRED" },
        { name = "gross_amount_minor", type = "INTEGER", mode = "REQUIRED" },
        { name = "refund_amount_minor", type = "INTEGER", mode = "REQUIRED" },
        { name = "reversal_amount_minor", type = "INTEGER", mode = "REQUIRED" },
        { name = "net_amount_minor", type = "INTEGER", mode = "REQUIRED" },
      ]
    }
    settlement_items = {
      partition_field = "settlement_date"
      clustering      = ["settlement_batch_id", "transaction_id", "status"]
      schema = [
        { name = "settlement_item_id", type = "STRING", mode = "REQUIRED" },
        { name = "settlement_batch_id", type = "STRING", mode = "REQUIRED" },
        { name = "transaction_id", type = "STRING", mode = "REQUIRED" },
        { name = "settlement_date", type = "DATE", mode = "REQUIRED" },
        { name = "currency", type = "STRING", mode = "REQUIRED" },
        { name = "gross_amount_minor", type = "INTEGER", mode = "REQUIRED" },
        { name = "refund_amount_minor", type = "INTEGER", mode = "REQUIRED" },
        { name = "reversal_amount_minor", type = "INTEGER", mode = "REQUIRED" },
        { name = "net_amount_minor", type = "INTEGER", mode = "REQUIRED" },
        { name = "status", type = "STRING", mode = "REQUIRED" },
      ]
    }
    daily_control_totals = {
      partition_field = "business_date"
      clustering      = ["currency", "control_status"]
      schema = [
        { name = "business_date", type = "DATE", mode = "REQUIRED" },
        { name = "currency", type = "STRING", mode = "REQUIRED" },
        { name = "transaction_count", type = "INTEGER", mode = "REQUIRED" },
        { name = "transaction_amount_minor", type = "INTEGER", mode = "REQUIRED" },
        { name = "refund_count", type = "INTEGER", mode = "REQUIRED" },
        { name = "refund_amount_minor", type = "INTEGER", mode = "REQUIRED" },
        { name = "reversal_count", type = "INTEGER", mode = "REQUIRED" },
        { name = "reversal_amount_minor", type = "INTEGER", mode = "REQUIRED" },
        { name = "settlement_item_count", type = "INTEGER", mode = "REQUIRED" },
        { name = "settlement_net_amount_minor", type = "INTEGER", mode = "REQUIRED" },
        { name = "control_status", type = "STRING", mode = "REQUIRED" },
      ]
    }
  }
}

resource "google_bigquery_table" "phase26_financial" {
  for_each = var.enable_phase26_financial_ops ? local.phase26_financial_tables : {}

  project             = var.project_id
  dataset_id          = google_bigquery_dataset.phase26_financial[0].dataset_id
  table_id            = each.key
  deletion_protection = true
  description         = "Project 08 Phase 26 fully synthetic financial-operations table: ${each.key}."

  dynamic "time_partitioning" {
    for_each = each.value.partition_field == null ? [] : [each.value.partition_field]
    content {
      type  = "DAY"
      field = time_partitioning.value
    }
  }

  clustering = length(each.value.clustering) > 0 ? each.value.clustering : null

  labels = {
    project             = "project08"
    environment         = var.environment
    layer               = "financial-ops"
    purpose             = "synthetic-financial-operations"
    data_classification = "synthetic-only"
    managed_by          = "terraform"
  }

  schema = jsonencode(each.value.schema)
}
