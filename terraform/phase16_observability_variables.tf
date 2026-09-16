variable "enable_phase16_observability" {
  description = "Enable Phase 16 operational observability tables and Cloud Logging/Monitoring controls."
  type        = bool
  default     = false
}

variable "phase16_observability_log_id" {
  description = "Structured Cloud Logging log id used by the Phase 16 runtime proof."
  type        = string
  default     = "project08_phase16_observability"
}

variable "phase16_sla_log_metric_name" {
  description = "User-defined logs-based metric for Phase 16 SLA breaches."
  type        = string
  default     = "project08_phase16_sla_breach_count"
}

variable "phase16_alert_policy_display_name" {
  description = "Display name for the Phase 16 SLA breach log alert policy."
  type        = string
  default     = "Project 08 Phase 16 SLA Breach"
}

variable "phase16_cost_metric_require_partition_filter" {
  description = "Require a captured_at partition filter on audit.cost_metric after controlled activation proof."
  type        = bool
  default     = true
}
