locals {
  env                    = var.cyngular_project_number == "839416416471" ? "prod" : "dev"
  cyngular_project_id    = "cyngular-${var.client_name}"
  cyngular_sa_base_email = "${var.client_name}@cyngular-${local.env}.iam.gserviceaccount.com"

  enabled_apis = [
    "bigquery.googleapis.com",
    "compute.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]
  organization_audit_logs = {
    enable_random_bucket_suffix = true
    bq_dataset_name             = var.big_query_dataset_name != "" ? var.big_query_dataset_name : "${var.client_name}_cyngular_sink"
  }

  cloud_function = {
    bucket_location   = var.client_main_region
    function_location = var.client_main_region
    name              = "cyngular-function"

    env_vars = {
      "PROJECT_ID" = var.big_query_project_id != "" ? var.big_query_project_id : local.cyngular_project_id
      "DATASET_ID" = local.organization_audit_logs.bq_dataset_name
      "LOCATION"   = var.big_query_dataset_location != "" ? var.big_query_dataset_location : var.client_main_region
    }

    project_permissions = [
      "roles/bigquery.jobUser"
    ]
    org_permissions = [
      "roles/viewer",
      "roles/browser"
    ]
  }
  function_sa_permissions = [for role in local.cloud_function.project_permissions : "${local.cyngular_project_id}=>${role}"]

  cyngular_org_role = {
    name = "cyngularOrgRole"
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
      role_id     = "gkeCsiSnapshotReader"
      title       = "GKE CSI Snapshot Reader"
      description = "GKE CSI driver read snapshots for cross-project VolumeSnapshotContent"
      permissions = [
        "compute.snapshots.get",
        # "compute.snapshots.list",
      ]
    }
  }
}