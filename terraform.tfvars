# default values for the module

organization_id = "1111111111111111111"

billing_account = "XXXXXX-YYYYYY-ZZZZZZ" # Format: 6 chars - 6 chars - 6 chars

client_name = "acme"
organization_audit_logs = {
  log_configuration = {
    enable_admin_read = false
    enable_data_read  = false
    enable_data_write = false
  }
  enable_bigquery_export = true
  # existing_bq_dataset = {
  #   dataset_id = "DATASET_ID"
  #   project_id = "CLIENT-PROJECT-ID"
  # }
  # bq_location = "europe-west4"
}

# cloud_function = {
#   env_vars = {
#     "PROJECT_ID" = "acme-cyngular"      # This will match the project created by Terraform
#     "DATASET_ID" = "acme_cyngular_sink" # This will match the dataset from organization_audit_logs
#     "LOCATION"   = "us-central1"        # Same as cloud function location
#   }
# }

# cyngular_sa_base_email = "SA_NAME@PROJECT_ID.iam.gserviceaccount.com"
# cyngukar_project_id = "acme-project"
