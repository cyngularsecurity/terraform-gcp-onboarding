organization_id = "1111111111111111111"
billing_account = "AAAAAA-BBBBBB-CCCCCC"

client_name = "clientname"

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

cloud_function = {
  env_vars = {
    "ENV_VAR_1" = "value1"
    "ENV_VAR_2" = "value2"
  }
}