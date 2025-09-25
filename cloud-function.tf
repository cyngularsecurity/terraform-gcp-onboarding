locals {
  function_sa_permissions = [for role in local.cloud_function.project_permissions : "${var.project_id}=>${role}"]
}

data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "${path.module}/code"
  output_path = "${path.module}/function-source.zip"
}

resource "google_storage_bucket" "bucket" {
  depends_on = [ google_project_service.project ]
  name                        = "${var.project_id}-gcf-source"
  location                    = local.cloud_function.bucket_location
  uniform_bucket_level_access = true
  project                     = var.project_id
}

resource "google_storage_bucket_object" "function_source" {
  depends_on = [ google_project_service.project ]
  name   = "function-source-${data.archive_file.function_source.output_md5}.zip"
  bucket = google_storage_bucket.bucket.name
  source = data.archive_file.function_source.output_path
}

module "cloud_function" {
  depends_on = [ 
    module.cloud_build_sa,
    module.cloud_function_sa,
    google_project_service.project,
    module.organization_audit_logs
  ]
  source  = "GoogleCloudPlatform/cloud-functions/google"
  version = "~> 0.6"

  project_id        = var.project_id
  function_name     = local.cloud_function.name
  function_location = local.cloud_function.function_location
  runtime           = "python311"
  entrypoint        = "http_trigger"
  storage_source = {
    bucket     = google_storage_bucket.bucket.name
    object     = google_storage_bucket_object.function_source.name
    generation = null
  }
  build_service_account = module.cloud_build_sa.service_account.name
  service_config = {
    max_instance_count = 1
    service_account_email = module.cloud_function_sa.email
    runtime_env_variables = var.cloud_function.env_vars
  }
}

module "cloud_function_sa" {
  depends_on = [ google_project_service.project ]
  source        = "terraform-google-modules/service-accounts/google"
  version       = "~> 4.0"
  project_id    = var.project_id
  names         = ["cyngular-cf-sa"]
  project_roles = local.function_sa_permissions
}

module "cloud_build_sa" {
  depends_on = [ google_project_service.project ]
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 4.0"
  project_id = var.project_id
  names      = ["cyngular-cloud-build-sa"]
  project_roles = [
    "${var.project_id}=>roles/logging.logWriter",
    "${var.project_id}=>roles/artifactregistry.writer",
    "${var.project_id}=>roles/storage.objectViewer"
  ]
}
resource "google_organization_iam_member" "cloud_function_roles" {
  depends_on = [ google_project_service.project ]
  for_each   = toset(local.cloud_function.org_permissions)
  org_id     = var.organization_id
  role       = each.value
  member     = "serviceAccount:${module.cloud_function_sa.email}"
}

resource "time_sleep" "wait_for_cloud_function" {
  depends_on = [module.cloud_function]
  create_duration = "60s"
}

resource "null_resource" "call_cloud_function" {
  depends_on = [
    module.cloud_function,
    time_sleep.wait_for_cloud_function,
    module.organization_audit_logs
  ]
  provisioner "local-exec" {
    command = "curl -H \"Authorization: Bearer $(gcloud auth print-identity-token)\" ${module.cloud_function.function_uri}"
  }
}
