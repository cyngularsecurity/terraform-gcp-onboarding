resource "time_sleep" "wait_for_sa" {
  create_duration = "60s"

  depends_on = [module.cloud_function_sa]
}

module "cloud_function" {
  source  = "GoogleCloudPlatform/cloud-functions/google"
  version = "~> 0.6"

  project_id            = var.cyngular_project_id
  function_name         = local.cloud_function.name
  function_location     = var.function_location
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
    module.cloud_build_sa,
    module.cloud_function_sa,
    terraform_data.wait_for_build_sa_permissions,
    time_sleep.wait_for_sa
  ]
}

