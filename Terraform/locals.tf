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
    audit_bucket_name = "${var.client_name}-cyngular-sink-storage" # Review
    bq_dataset_name = "${var.client_name}_cyngular_sink" # Review
  }

  cloud_function = {
    bucket_location = "us-central1"
    function_location = "us-central1"
    name = "cyngular-function" 
    project_permissions = [
       "roles/bigquery.dataEditor",
       "roles/bigquery.dataViewer",
       "roles/bigquery.jobUser"
      ]
    org_permissions = [
       "roles/viewer"
    ]
    env_vars = {
      "key" = "value"
    }
  }

  cyngular_sa = { 
    project_permissions = [
       "roles/run.invoker" 
      ]
    org_permissions = [ 
      "roles/viewer",
      "roles/browser",
      "roles/bigquery.dataViewer",
      "roles/bigquery.jobUser",
      "roles/compute.storageAdmin",
    ]
    base_sa_email = "github-sa@leonv-sandbox.iam.gserviceaccount.com"
  }
}