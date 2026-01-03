output "enable_bigquery_export" {
  value       = local.enable_cyngular_bigquery_export
  description = "logical output of dataset name"
}

output "bq_details" {
  value = local.enable_cyngular_bigquery_export ? {
    dataset_id   = module.destination_dataset[0].resource_id
    project_id   = module.destination_dataset[0].project
    dataset_name = module.destination_dataset[0].resource_name
    } : {
    dataset_id   = local.dest_dataset_id
    project_id   = var.bq_dataset_project_id
    dataset_name = var.bq_dataset_name
  }
  description = "The details of the BigQuery dataset"
}