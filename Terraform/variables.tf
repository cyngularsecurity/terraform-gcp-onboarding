
variable "organization_id" {
  description = "Organization ID to deploy resources in"
  type        = string
}

variable "billing_account" {
  description = "Billing account to create resources with"
  type        = string
}

variable "organization_audit_logs" {
  description = "Configures audit logs for organization"
  type = object({
    log_configuration = optional(object({
      enable_admin_read             = bool,
      enable_data_read              = bool,
      enable_data_write             = bool, 
    }))
    enable_bigquery_export        = bool
    bq_location                   = optional(string),
  })
  default = null
}

variable "client_name" {
  description = "Name of the client"
  type        = string
}

variable "cloud_function" {
  type = object({
    env_vars = map(string)
  })
}