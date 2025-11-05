module "organization_audit_logs" {
  source = "./modules/audit_logs"

  org_id                    = var.organization_id
  audit_log_configuration   = var.organization_audit_logs.log_configuration
  destination_audit_project = local.cyngular_project_id
  bq_dataset_name           = local.organization_audit_logs.bq_dataset_name
  enable_bigquery_export    = var.organization_audit_logs.enable_bigquery_export
  bigquery_location         = var.organization_audit_logs.bq_location
  existing_bq_dataset       = var.organization_audit_logs.existing_bq_dataset

  cyngular_sa_email = module.cyngular_sa.email
  function_sa_email = module.cloud_function_sa.email

  depends_on = [google_project_service.project]
}