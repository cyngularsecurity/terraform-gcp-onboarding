module "organization_audit_logs" {
  depends_on = [ module.project ]
  source                      = "./modules/audit_logs"
  org_id                      = var.organization_id
  audit_log_configuration      = var.organization_audit_logs.log_configuration
  destination_audit_project   = local.project_config.project_id
  bq_dataset_name = local.organization_audit_logs.bq_dataset_name
  enable_bigquery_export      = var.organization_audit_logs.enable_bigquery_export
  bigquery_location = var.organization_audit_logs.bq_location
}