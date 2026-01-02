variable "organization_id" {
  description = "GCP organization ID where resources will be deployed"
  type        = string
}

variable "cyngular_project_id" {
  description = "GCP project ID where resources will be deployed"
  type        = string
}

variable "bucket_location" {
  description = "GCP bucket location where resources will be deployed"
  type        = string
}

variable "function_location" {
  description = "GCP function location where resources will be deployed"
  type        = string
}


# -----
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
