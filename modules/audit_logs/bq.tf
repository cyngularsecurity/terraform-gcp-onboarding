# Creates organization-level log sink that exports CloudAudit logs to BigQuery
# This module is OPTIONAL - only created if enable_cyngular_bigquery_export=true
# Otherwise presumed to use the client's existing BigQuery dataset
#
# The log sink:
#   - Captures CloudAudit logs (activity, system_event, policy) from the entire organization
#   - Has include_children=true: monitors ALL projects under the organization automatically
#   - Sends logs to a BigQuery dataset for analysis and security monitoring by Cyngular
module "log_export_bq" {
  source  = "terraform-google-modules/log-export/google"
  version = "~> 10.0"

  count = local.enable_cyngular_bigquery_export ? 1 : 0

  destination_uri = module.destination_dataset[0].destination_uri
  filter          = "logName: \"/logs/cloudaudit.googleapis.com%2Factivity\" OR logName: \"/logs/cloudaudit.googleapis.com%2Fsystem_event\" OR logName: \"logs/cloudaudit.googleapis.com%2Fpolicy\""
  # log_sink_name          = "cyngular-audit-logs-bq"
  log_sink_name          = "cyngular-audit-logs-bq-${var.client_name}"
  parent_resource_id     = var.org_id
  parent_resource_type   = "organization"
  unique_writer_identity = true
  include_children       = true

  # Drop high-volume, low-value K8s/operator lease & status-update events
  exclusions = [
    {
      name        = "exclude-noisy-operator-status-updates"
      description = "Filter out high-volume, low-value K8s/operator lease and status-update audit events"
      disabled    = false
      filter      = local.noisy_methods_exclusion_filter
    }
  ]
}

# Creates BigQuery dataset in the Cyngular project to store exported audit logs
# Location can be configured via bq_dataset_location variable (default to client main location)
module "destination_dataset" {
  source = "terraform-google-modules/log-export/google//modules/bigquery"
  count  = local.enable_cyngular_bigquery_export ? 1 : 0

  project_id               = var.destination_audit_project // cyngular project @ client org
  dataset_name             = var.bq_dataset_name
  log_sink_writer_identity = module.log_export_bq[0].writer_identity
  location                 = var.bq_dataset_location
}
