variable "enable_phase24_streaming_lab" {
  description = "Enable ephemeral Phase 24 Pub/Sub + Dataflow mini-lab foundation."
  type        = bool
  default     = false
}

variable "phase24_operator_email" {
  description = "Private operator email allowed to launch Dataflow with the Phase 24 worker identity."
  type        = string
  sensitive   = true
  default     = ""
}

variable "phase24_topic_name" {
  description = "Phase 24 synthetic event topic name."
  type        = string
  default     = "p08-phase24-events"
}

variable "phase24_subscription_name" {
  description = "Phase 24 validation subscription name."
  type        = string
  default     = "p08-phase24-validation"
}

variable "phase24_dataflow_subscription_name" {
  description = "Phase 24 dedicated Dataflow input subscription name."
  type        = string
  default     = "p08-phase24-dataflow"
}
