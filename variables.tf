variable "client_name" {
  description = "Client organization name (lowercase letters and numbers only, must start and end with a letter)"
  type        = string
  validation {
    condition = can(regex("^[a-z](?:[a-z0-9]{0,11}[a-z])?$", var.client_name))

    error_message = "client_name must contain only lowercase letters and numbers, and must start and end with a letter"
  }
}

variable "client_main_location" {
  description = "Primary GCP location for client resources"
  type        = string
}

variable "organization_id" {
  description = "GCP organization ID where resources will be deployed"
  type        = string
}

# -----------
variable "billing_account" {
  description = "GCP billing account ID (format: XXXXXX-YYYYYY-ZZZZZZ)"
  type        = string
}

variable "cyngular_project_folder_id" {
  description = "GCP folder ID to create project under. Creates under organization if empty"
  type        = string
  default     = ""
}

# -----------
variable "existing_bigquery_dataset" {
  description = <<EOF
    Optional configuration for using an existing BigQuery dataset instead of creating a new one.
    If null (default), a new BigQuery dataset will be created in the Cyngular project.
    If provided, audit logs will be exported to the specified existing dataset.

    Required fields:
      - dataset_name: The name of the existing BigQuery dataset
      - project_id: The GCP project ID containing the dataset

    Optional fields:
      - location: The dataset location (defaults to client_main_location if not provided)

    Example:
      existing_bigquery_dataset = {
        dataset_name = "existing_audit_logs"
        project_id   = "shared-logging-project"
        location     = "us-east4"  # Optional
      }
  EOF
  type = object({
    dataset_name = string
    project_id   = string
    location     = optional(string, "")
  })
  default = null

  validation {
    condition = var.existing_bigquery_dataset == null ? true : (
      var.existing_bigquery_dataset.dataset_name != "" &&
      var.existing_bigquery_dataset.project_id != ""
    )
    error_message = "When existing_bigquery_dataset is provided, both dataset_name and project_id must be non-empty strings."
  }
}

# -----------

variable "organization_audit_logs" {
  description = <<EOF
    Organization audit log configuration.
    Provide the existing BigQuery dataset details if you want to use an existing dataset instead of creating a new one.

    EOF
  type = object({
    log_configuration = optional(map(bool))
  })
  default = {
    log_configuration = {
      "ADMIN_READ" = true
      "DATA_READ"  = false
      "DATA_WRITE" = false
    }
  }
}
variable "cyngular_project_number" {
  description = <<EOF
    Cyngular's GCP project number - determines which Cyngular environment this client connects to

    Available environments:
      - Dev:  248189932415 (project: cyngular-dev)  - For testing and development clients
      - Prod: 839416416471 (project: cyngular-prod) - For production clients

    This value is used for:
      1. Environment detection (locals.tf) - determines if this is dev/prod deployment
      2. GKE CSI snapshot permissions (iam.tf) - grants Cyngular's GKE Container Engine service account
         permission to read disk snapshots from this client project for backup/disaster recovery

    Find project number: https://console.cloud.google.com/iam-admin/settings?project=<project name>
  EOF
  type        = string
  default     = "839416416471" # Default to prod
  validation {
    condition     = length(var.cyngular_project_number) == 12
    error_message = "cyngular_project_number must be 12 digits"
  }
}