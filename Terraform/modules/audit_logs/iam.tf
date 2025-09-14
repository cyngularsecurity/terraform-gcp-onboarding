resource "google_bigquery_dataset_iam_member" "cyngular_sa" {
  for_each = toset(local.bq_cyngular_sa_permissions)
  project = var.enable_bigquery_export ? var.destination_audit_project : var.existing_bq_dataset.project_id
  dataset_id = var.enable_bigquery_export ? module.destination_dataset[0].resource_name : var.existing_bq_dataset.dataset_id
  role       = each.value
  member     = "serviceAccount:${var.cyngular_sa_email}"
}

resource "google_bigquery_dataset_iam_member" "function_sa" {
  for_each = toset(local.bq_function_sa_permissions)
  project = var.enable_bigquery_export ? var.destination_audit_project : var.existing_bq_dataset.project_id
  dataset_id = var.enable_bigquery_export ? module.destination_dataset[0].resource_name : var.existing_bq_dataset.dataset_id
  role       = each.value
  member     = "serviceAccount:${var.function_sa_email}"
}