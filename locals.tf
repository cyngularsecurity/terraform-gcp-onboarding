locals {
  env                 = var.cyngular_project_number == "839416416471" ? "prod" : var.cyngular_project_number == "1006301876718" ? "stg" : "dev"
  
  generated_project_id = "cyngular-${var.client_name}"

  # Use generated_project_id (a statically-known value) instead of google_project.cyngular_project[0].id
  # (an apply-time value). Both are identical, but using the static form prevents "for_each keys
  # derived from unknown values" errors in downstream resources like module.cyngular_sa.
  cyngular_project_id = var.existing_project_id != null ? var.existing_project_id : local.generated_project_id

  # service account names must be no less than 6 characters long
  client_sa_name         = length(var.client_name) < 6 ? "${var.client_name}-sa" : var.client_name
  cyngular_sa_base_email = "${local.client_sa_name}@cyngular-${local.env}.iam.gserviceaccount.com"

  enabled_apis = [
    "bigquery.googleapis.com",
    "compute.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]

  enable_random_bucket_suffix = true

  # Determine if we should create a new BigQuery dataset or use an existing one
  # If existing_bigquery_dataset is null, create a new dataset in the Cyngular project
  # If existing_bigquery_dataset is provided, use the existing dataset
  enable_cyngular_bigquery_export = var.existing_bigquery_dataset == null

  # BigQuery dataset configuration
  # For new datasets: use default naming and Cyngular project
  # For existing datasets: use provided configuration
  existing_bq_ds_location = try(var.existing_bigquery_dataset.location, "")

  bq_dataset_name       = var.existing_bigquery_dataset != null ? var.existing_bigquery_dataset.dataset_name : "${var.client_name}_cyngular_sink"
  bq_dataset_location   = local.existing_bq_ds_location != "" ? local.existing_bq_ds_location : var.client_main_location
  bq_dataset_project_id = var.existing_bigquery_dataset != null ? var.existing_bigquery_dataset.project_id : local.cyngular_project_id

  cloud_function = {
    name = "cyngular-function"

    bucket_location   = var.client_main_location
    function_location = var.client_main_location
  }

  cyngular_org_role = {
    # name = "cyngularOrgRole"
    name = "cyngular_org_role_${var.client_name}"
    permissions = [
      "compute.disks.createSnapshot",
      "compute.snapshots.create",
      "compute.snapshots.getIamPolicy",
      "compute.snapshots.setIamPolicy",
      "compute.snapshots.useReadOnly",
      "compute.snapshots.get",    # View info about the snapshot
      "compute.snapshots.delete", # Needed for delete
      "compute.snapshots.list",   # Needed for delete
    ]
  }
  cyngular_sa = {
    project_permissions = [
      "roles/run.invoker",
      "roles/bigquery.jobUser",
    ]
    org_permissions = [
      "roles/viewer",
      "roles/browser",
    ]
  }

  cyngular_sa_permissions = [for role in local.cyngular_sa.project_permissions : "${local.cyngular_project_id}=>${role}"]

  gke_csi_snapshot = {
    enabled = true
    custom_role = {
      role_id     = "gke_csi_snapshot_reader"
      title       = "GKE CSI Snapshot Reader"
      description = "GKE CSI driver read snapshots for cross-project VolumeSnapshotContent"
      permissions = [
        "compute.snapshots.get",
      ]
    }
  }
}