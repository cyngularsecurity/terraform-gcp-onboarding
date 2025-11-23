variable "client_name" {
  description = "Client organization name (lowercase letters and numbers only)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.client_name))
    error_message = "client_name must contain only lowercase letters and numbers"
  }
}

variable "client_main_region" {
  description = "Primary GCP region for client resources"
  type        = string
}
variable "organization_id" {
  description = "GCP organization ID where resources will be deployed"
  type        = string
}
variable "billing_account" {
  description = "GCP billing account ID (format: XXXXXX-YYYYYY-ZZZZZZ)"
  type        = string
}

variable "cyngular_project_folder_id" {
  description = "GCP folder ID to create project under. Creates under organization if empty"
  type        = string
  default     = ""
}
variable "big_query_project_id" {
  description = "Custom project ID for BigQuery export. Defaults to 'cyngular-{client_name}' if empty"
  type        = string
  default     = ""
}
variable "big_query_dataset_name" {
  description = "Custom dataset name for BigQuery export. Defaults to 'cyngular-{client_name}' if empty"
  type        = string
  default     = ""
}
variable "big_query_dataset_location" {
  description = "Custom dataset location for BigQuery export. Defaults to 'us-east4' if empty"
  type        = string
  default     = ""
}

variable "organization_audit_logs" {
  description = "Organization audit log configuration. Set enable_bigquery_export=true to create new dataset or false to use existing_bq_dataset"
  type = object({
    log_configuration = optional(object({
      enable_admin_read = bool
      enable_data_read  = bool
      enable_data_write = bool
    }))

    enable_bigquery_export = bool
    bq_location            = optional(string, "us-east4")
    existing_bq_dataset = optional(object({
      dataset_id = string
      project_id = string
    }), null)
  })
  # default = null
}
variable "cyngular_project_number" {
  description = "Cyngular project number for GKE CSI cross-project snapshot access (12 digits)"
  type        = string
  default     = "839416416471"
  validation {
    condition     = length(var.cyngular_project_number) == 12
    error_message = "cyngular_project_number must be 12 digits"
  }
}

# variable "cyngular_sa_base_email" {
#   description = "DEPRECATED: Auto-generated. Cyngular service account email for impersonation"
#   type        = string
#   default     = ""
# }

# variable "cyngular_project_id" {
#   description = "Custom project ID for Cyngular project. Defaults to 'cyngular-{client_name}' if empty"
#   type        = string
#   default     = ""
# }
