locals {
  cloud_function = {
    name = "cyngular-function"

    env_vars = {
      "LOCATION"   = var.bq_dataset_location
      "PROJECT_ID" = var.bq_dataset_project_id
      "DATASET_ID" = var.bq_dataset_name
    }

    project_permissions = [
      "roles/bigquery.jobUser"
    ]
    org_permissions = [
      "roles/viewer",
      "roles/browser"
    ]
  }

  function_sa_project_permissions = [
    for role in local.cloud_function.project_permissions :
    "${var.cyngular_project_id}=>${role}"
  ]
}