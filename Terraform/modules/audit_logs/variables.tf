variable "org_id" {
  type        = string
  description = "The Organization Id"
}

variable "audit_log_configuration" {
  type = object({
    enable_admin_read = bool
    enable_data_read  = bool
    enable_data_write = bool
  })
  description = "Configuration for which audit logs to enable"
}

variable "destination_audit_project" {
  type = string
  description = "Project ID where the audit logs will be sent to"
}


variable "bq_dataset_name" {
  type    = string
  description = "Configures the name of the BigQuery dataset"
  default = null
}


variable "enable_bigquery_export" {
  description = "Enable export of audit logs to BigQuery"
  type        = bool
}


variable "bigquery_location" {
  type        = string
  description = "The location for the BigQuery dataset"
  default     = null
}