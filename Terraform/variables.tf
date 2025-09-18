
variable "organization_id" {
  description = "Organization ID to deploy resources in"
  type        = string
}

variable "organization_audit_logs" {
  description = <<EOF
  "Configures audit logs and sink for organization"
  If enable_bigquery_export is false, existing_bq_dataset must be provided.
  If enable_bigquery_export is true, existing_bq_dataset is ignored.
  If enable_bigquery_export is true and bq_location is not provided, us-east4 is used for the default.
  
  log_configuration - Configuration for which audit logs to enable
    enable_admin_read - Enable admin read audit logs
    enable_data_read  - Enable data read audit logs
    enable_data_write - Enable data write audit logs
EOF
  
  type = object({
    log_configuration = optional(object({
      enable_admin_read = bool,
      enable_data_read  = bool,
      enable_data_write = bool,
    }))
    enable_bigquery_export = bool
    bq_location            = optional(string, "us-east4"),
    existing_bq_dataset   = optional(object({
      dataset_id          = string
      project_id  = string
    }),null)
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

variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "cyngular_sa_base_email" {
  description = "Service account email that will impersonate the service account created"
  type        = string
}