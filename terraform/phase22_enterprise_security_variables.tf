variable "enable_phase22_enterprise_security" {
  description = "Enterprise-only Phase 22 resources. Must remain false in the personal Project 08 environment."
  type        = bool
  default     = false
}

variable "phase22_organization_id" {
  description = "Enterprise organization ID. Private input; intentionally unset for Project 08."
  type        = string
  sensitive   = true
  default     = ""
}

variable "phase22_project_number" {
  description = "Enterprise protected project number. Private input; intentionally unset for Project 08."
  type        = string
  sensitive   = true
  default     = ""
}

variable "phase22_trusted_cidrs" {
  description = "Synthetic documentation CIDRs used only by the disabled design lab."
  type        = list(string)
  default     = ["198.51.100.0/24", "203.0.113.0/24"]
}
