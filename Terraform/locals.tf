locals {
  project_config = {
    project_id = "${var.client_name}-cyngular" # Review
    apis = [
      "bigquery.googleapis.com",
      "compute.googleapis.com",
      "cloudfunctions.googleapis.com",
      "cloudbuild.googleapis.com",
      "run.googleapis.com"
    ]
  }
  organization_audit_logs = {
    enable_random_bucket_suffix = true
    bq_dataset_name             = "${var.client_name}_cyngular_sink"         # Review
  }

  cloud_function = {
    bucket_location   = "us-central1"
    function_location = "us-central1"
    name              = "cyngular-function"
    project_permissions = [
      "roles/bigquery.jobUser"
    ]
    org_permissions = [
      "roles/viewer",
      "roles/browser"
    ]
  }

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
    base_sa_email = "github-sa@leonv-sandbox.iam.gserviceaccount.com"
  }

  cyngular_sa_permissions = [ for role in local.cyngular_sa.project_permissions : "${local.project_config.project_id}=>${role}" ]
}