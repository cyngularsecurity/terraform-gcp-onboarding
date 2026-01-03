locals {
  enable_cyngular_bigquery_export = var.enable_cyngular_bigquery_export

  # Fix: resource_id returns full path (projects/{project}/datasets/{dataset_id}), 
  # but IAM resource expects just the dataset name/id.
  dest_dataset_id = local.enable_cyngular_bigquery_export ? module.destination_dataset[0].resource_name : var.bq_dataset_name

  # currently same permissions
  bq_cyngular_sa_permissions = [
    "roles/bigquery.dataEditor",
  ]
  bq_function_sa_permissions = [
    "roles/bigquery.dataEditor",
  ]
}