resource "google_bigquery_dataset_iam_member" "cyngular_sa" {
  for_each = toset(local.bq_cyngular_sa_permissions)

  role = each.value

  ## determind in root - if using existing - must be also provided - if not - using cyngular's
  project    = var.bq_dataset_project_id

  # dataset_id = local.enable_cyngular_bigquery_export ? module.destination_dataset[0].resource_name : "projects/${var.bq_dataset_project_id}/datasets/${var.bq_dataset_name}"
  dataset_id = local.dest_dataset_id
  member     = "serviceAccount:${var.cyngular_sa_email}"
}

resource "google_bigquery_dataset_iam_member" "function_sa" {
  for_each = toset(local.bq_function_sa_permissions)

  role = each.value

  project    = var.bq_dataset_project_id
  dataset_id = local.dest_dataset_id
  member     = "serviceAccount:${var.function_sa_email}"
}