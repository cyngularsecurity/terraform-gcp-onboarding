variable "org_id" {
  type        = string
  description = "The Organization Id"
}

variable "client_name" {
  type        = string
  description = "The client name"
}

variable "audit_log_configuration" {
  type        = map(bool)
  description = "Configuration for which audit logs to enable (e.g., ADMIN_READ = true)"
  default     = {}
}

variable "destination_audit_project" {
  type        = string
  description = "Project ID where the audit logs will be sent to"
}

variable "enable_cyngular_bigquery_export" { // currently not using tf local
  type        = bool
  description = "Enable export of audit logs to BigQuery"
}

variable "bq_dataset_name" {
  type        = string
  description = "Configures the name of the BigQuery dataset"
}

variable "bq_dataset_location" {
  type        = string
  description = "The location for the BigQuery dataset"
}

variable "bq_dataset_project_id" {
  type        = string
  description = "The project ID for the BigQuery dataset"
}

variable "cyngular_sa_email" {
  type        = string
  description = "The email of the Cyngular service account that permission is granted to"
}
variable "function_sa_email" {
  type        = string
  description = "The email of the Cyngular service account that permission is granted to"
}

# variable "existing_bq_dataset" {
#   type = object({
#     dataset_id = string
#     project_id = string
#   })
#   description = <<EOF
#   Provide the existing BigQuery dataset details if you want to use an existing dataset instead of creating a new one.
#   Ignored if enabled_bigquery_export is true.
#   Must be set if enabled_bigquery_export is false.
#     dataset_id - The ID of the dataset.
#     project_id - The ID of the project containing the dataset.
# EOF
#   default     = null
# }

# variable "enable_bigquery_export" {
#   description = "Enable export of audit logs to BigQuery"
#   type        = bool
# }

# variable "bigquery_location" {
#   type        = string
#   description = "The location for the BigQuery dataset"
#   # default     = null
# }
