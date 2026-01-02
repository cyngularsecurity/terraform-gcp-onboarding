locals {
  enable_cyngular_bigquery_export = var.enable_cyngular_bigquery_export

  dest_dataset_id = local.enable_cyngular_bigquery_export ? module.destination_dataset[0].resource_id : var.bq_dataset_name

  # currently same permissions
  bq_cyngular_sa_permissions = [
    "roles/bigquery.dataEditor",
  ]
  bq_function_sa_permissions = [
    "roles/bigquery.dataEditor",
  ]
}