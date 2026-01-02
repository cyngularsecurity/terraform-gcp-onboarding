################################################################################
# PROJECT OUTPUTS
################################################################################
output "project_id" {
  value       = google_project.cyngular_project.project_id
  description = "The Cyngular project ID (e.g., cyngular-acme)"
}
output "project_name" {
  value       = google_project.cyngular_project.name
  description = "The Cyngular project display name"
}
output "project_number" {
  value       = google_project.cyngular_project.number
  description = "The Cyngular project number (12-digit unique identifier)"
}

################################################################################
# SERVICE ACCOUNT OUTPUTS
################################################################################
# output "cyngular_sa_name" {
#   value       = module.cyngular_sa.service_account.name
#   description = "Primary Cyngular service account resource name (fully qualified)"
# }
output "cyngular_sa_email" { // Target / Client's
  value       = module.cyngular_sa.email
  description = "Primary Cyngular service account email for monitoring and snapshot operations"
}

output "cyngular_sa_base_email" {
  value       = local.cyngular_sa_base_email
  description = "Base (Source) Cyngular service account email for impersonation (in cyngular-dev/prod project)"
}

################################################################################
# AUDIT LOGS & BIGQUERY OUTPUTS
################################################################################
output "audit_logs_enabled" {
  value = {
    admin_read  = try(var.organization_audit_logs.log_configuration["ADMIN_READ"], false)
    data_read   = try(var.organization_audit_logs.log_configuration["DATA_READ"], false)
    data_write  = try(var.organization_audit_logs.log_configuration["DATA_WRITE"], false)
  }
  description = "Organization audit log types enabled for collection"
}

output "bigquery_dataset_name" {
  value       = try(module.organization_audit_logs.bq_details.dataset_name, null)
  description = "BigQuery dataset name where audit logs are exported"
}
output "bigquery_dataset_project" {
  value       = try(module.organization_audit_logs.bq_details.project_id, null)
  description = "GCP project ID containing the BigQuery audit log dataset"
}
# output "bigquery_dataset_location" {
#   value       = var.organization_audit_logs.bq_location != null ? var.organization_audit_logs.bq_location : var.client_main_location
#   description = "Geographic location of the BigQuery dataset"
# }

output "bigquery_dataset_console_url" {
  value       = try("https://console.cloud.google.com/bigquery?project=${module.organization_audit_logs.bq_details.project_id}&p=${module.organization_audit_logs.bq_details.project_id}&d=${module.organization_audit_logs.bq_details.dataset_name}&page=dataset", null)
  description = "Direct URL to view the BigQuery dataset in GCP Console"
}

################################################################################
# CLOUD FUNCTION OUTPUTS
################################################################################
output "cloud_function_console_url" {
  value       = "https://console.cloud.google.com/functions/details/${local.cloud_function.function_location}/${local.cloud_function.name}?project=${local.cyngular_project_id}"
  description = "Direct URL to view Cloud Function in GCP Console"
}

################################################################################
# IAM & PERMISSIONS OUTPUTS
################################################################################
# output "custom_org_role_id" {
#   value       = google_organization_iam_custom_role.cyngular_custom.role_id
#   description = "Custom organization role ID for Cyngular snapshot operations"
# }

# output "gke_csi_service_account" {
#   value       = "service-${var.cyngular_project_number}@container-engine-robot.iam.gserviceaccount.com"
#   description = "GKE Container Engine Robot service account with snapshot read permissions"
# }

################################################################################
# CONFIGURATION SUMMARY
################################################################################
output "deployment_summary" {
  value = {
    client_name            = var.client_name
    region                 = var.client_main_location

    project_id             = google_project.cyngular_project.project_id
    organization_id        = var.organization_id

    enable_bigquery_export        = module.organization_audit_logs.enable_bigquery_export
    audit_logs_enabled     = var.organization_audit_logs.log_configuration != null && module.organization_audit_logs.enable_bigquery_export
  }
  description = "High-level summary of deployed Cyngular infrastructure"
}

################################################################################
# VERIFICATION & NEXT STEPS
################################################################################

# output "verification_commands" {
#   value = <<-EOT
#     # Verify project creation
#     gcloud projects describe ${google_project.cyngular_project.project_id}
    
#     # View Cloud Function
#     gcloud functions describe ${local.cloud_function.name} \
#       --project=${local.cyngular_project_id} \
#       --region=${local.cloud_function.function_location}
    
#     # Check BigQuery dataset (if enabled)
#     bq ls --project_id=${local.cyngular_project_id}
    
#     # List service accounts
#     gcloud iam service-accounts list --project=${local.cyngular_project_id}
    
#     # Test Cloud Function
#     curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" ${module.cloud_function.function_uri}
#   EOT
#   description = "Commands to verify successful deployment"
# }

# output "console_urls" {
#   value = {
#     project         = "https://console.cloud.google.com/home/dashboard?project=${local.cyngular_project_id}"
#     cloud_function  = "https://console.cloud.google.com/functions/details/${local.cloud_function.function_location}/${local.cloud_function.name}?project=${local.cyngular_project_id}"
#     bigquery        = try("https://console.cloud.google.com/bigquery?project=${module.organization_audit_logs.bq_details.project_id}&p=${module.organization_audit_logs.bq_details.project_id}&d=${module.organization_audit_logs.bq_details.dataset_name}&page=dataset", "N/A")
#     service_accounts = "https://console.cloud.google.com/iam-admin/serviceaccounts?project=${local.cyngular_project_id}"
#     iam_roles       = "https://console.cloud.google.com/iam-admin/roles?organizationId=${var.organization_id}"
#     audit_logs      = "https://console.cloud.google.com/logs/query?project=${local.cyngular_project_id}"
#   }
#   description = "Direct links to view resources in GCP Console"
# }
