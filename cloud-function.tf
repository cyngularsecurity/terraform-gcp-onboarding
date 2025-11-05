
data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "${path.module}/code"
  output_path = "${path.module}/function-source.zip"
}

resource "google_storage_bucket" "gcf_source" {
  name     = "${local.cyngular_project_id}-gcf-source"
  location = local.cloud_function.bucket_location
  project  = local.cyngular_project_id

  uniform_bucket_level_access = true

  depends_on = [google_project_service.project]
}

resource "google_storage_bucket_object" "function_source" {
  name   = "function-source-${data.archive_file.function_source.output_md5}.zip"
  bucket = google_storage_bucket.gcf_source.name
  source = data.archive_file.function_source.output_path

  depends_on = [google_project_service.project]
}

module "cloud_function" {
  source  = "GoogleCloudPlatform/cloud-functions/google"
  version = "~> 0.6"

  project_id            = local.cyngular_project_id
  function_name         = local.cloud_function.name
  function_location     = local.cloud_function.function_location
  runtime               = "python311"
  entrypoint            = "http_trigger"
  build_service_account = module.cloud_build_sa.service_account.name

  storage_source = {
    bucket     = google_storage_bucket.gcf_source.name
    object     = google_storage_bucket_object.function_source.name
    generation = null
  }
  service_config = {
    max_instance_count    = 1
    service_account_email = module.cloud_function_sa.email
    runtime_env_variables = local.cloud_function.env_vars
  }

  depends_on = [
    google_project_service.project,
    module.cloud_build_sa,
    module.cloud_function_sa,
    module.organization_audit_logs
  ]
}

module "cloud_function_sa" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "~> 4.0"

  project_id    = local.cyngular_project_id
  names         = ["cyngular-cf-sa"]
  project_roles = local.function_sa_permissions

  depends_on = [google_project_service.project]
}

module "cloud_build_sa" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "~> 4.0"

  project_id = local.cyngular_project_id
  names      = ["cyngular-cloud-build-sa"]
  project_roles = [
    "${local.cyngular_project_id}=>roles/logging.logWriter",
    "${local.cyngular_project_id}=>roles/artifactregistry.writer",
    "${local.cyngular_project_id}=>roles/storage.objectViewer"
  ]

  depends_on = [google_project_service.project]
}

resource "google_organization_iam_member" "cloud_function_roles" {
  for_each = toset(local.cloud_function.org_permissions)

  org_id = var.organization_id
  role   = each.value
  member = "serviceAccount:${module.cloud_function_sa.email}"

  depends_on = [google_project_service.project]
}

resource "terraform_data" "call_cloud_function" {
  provisioner "local-exec" {
    command = "sleep 60 && curl -H \"Authorization: Bearer $(gcloud auth print-identity-token)\" ${module.cloud_function.function_uri}"
  }

  depends_on = [
    module.cloud_function,
    module.organization_audit_logs
  ]
}
