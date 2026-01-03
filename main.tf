resource "google_project" "cyngular_project" {
  project_id          = local.cyngular_project_id
  org_id              = var.organization_id
  name                = "cyngular ${var.client_name}"
  billing_account     = var.billing_account
  auto_create_network = false
  deletion_policy     = "DELETE"
  folder_id           = var.cyngular_project_folder_id != "" ? var.cyngular_project_folder_id : null

  # lifecycle {
  #   prevent_destroy = true
  # }
}

module "cyngular_func" {
  source = "./modules/run"

  bucket_location   = local.cloud_function.bucket_location
  function_location = local.cloud_function.function_location

  bq_dataset_name       = local.bq_dataset_name
  bq_dataset_location   = local.bq_dataset_location
  bq_dataset_project_id = local.bq_dataset_project_id

  organization_id = var.organization_id

  cyngular_project_id = local.cyngular_project_id

  depends_on = [
    google_project_service.project,
  ]
}

module "organization_audit_logs" {
  source = "./modules/audit_logs"

  client_name = var.client_name
  org_id      = var.organization_id

  cyngular_sa_email = module.cyngular_sa.email
  function_sa_email = module.cyngular_func.function_sa_email

  # Computed based on whether existing_bigquery_dataset is provided
  enable_cyngular_bigquery_export = local.enable_cyngular_bigquery_export

  # sending audit logs from new / existing to cyngular project
  destination_audit_project = local.cyngular_project_id
  audit_log_configuration   = var.organization_audit_logs.log_configuration

  bq_dataset_name       = local.bq_dataset_name
  bq_dataset_location   = local.bq_dataset_location
  bq_dataset_project_id = local.bq_dataset_project_id

  depends_on = [google_project_service.project]
}