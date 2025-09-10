variable "client_project_id" {
  description = "The project ID in Client Organization"
  type        = string
}

variable "client_region" {
  description = "The region for resources"
  type        = string
  default     = "us-central1"
}

variable "source_org_service_account_email" {
  description = "The email of the service account from Source Organization"
  type        = string
}

# variable "cyngular_access_roles" {
#   description = "List of roles to be granted to the service account"
#   type        = list(string)
# }
