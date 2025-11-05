module "log_export_bq" {
  count = var.enable_bigquery_export ? 1 : 0

  source  = "terraform-google-modules/log-export/google"
  version = "~> 10.0"

  destination_uri        = module.destination_dataset[0].destination_uri
  filter                 = "logName: \"/logs/cloudaudit.googleapis.com%2Factivity\" OR logName: \"/logs/cloudaudit.googleapis.com%2Fsystem_event\" OR logName: \"logs/cloudaudit.googleapis.com%2Fdata_access\" OR logName: \"logs/cloudaudit.googleapis.com%2Fpolicy\""
  log_sink_name          = "cyngular-audit-logs-bq"
  parent_resource_id     = var.org_id
  parent_resource_type   = "organization"
  unique_writer_identity = true
  include_children       = true
}

module "destination_dataset" {
  count                    = var.enable_bigquery_export ? 1 : 0
  source                   = "terraform-google-modules/log-export/google//modules/bigquery"
  project_id               = var.destination_audit_project
  dataset_name             = var.bq_dataset_name
  log_sink_writer_identity = module.log_export_bq[0].writer_identity
  location                 = var.bigquery_location
}