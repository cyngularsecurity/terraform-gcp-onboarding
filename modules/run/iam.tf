module "cloud_function_sa" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "~> 4.0"

  names         = ["cyngular-cf-sa"]
  project_id    = var.cyngular_project_id

  project_roles = local.function_sa_project_permissions
}

module "cloud_build_sa" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "~> 4.0"

  names      = ["cyngular-cloud-build-sa"]
  project_id = var.cyngular_project_id

  project_roles = [
    "${var.cyngular_project_id}=>roles/logging.logWriter",
    "${var.cyngular_project_id}=>roles/artifactregistry.writer",
    "${var.cyngular_project_id}=>roles/storage.objectViewer"
  ]
}

## org permissions only for the function to use - not required for build sa 
resource "google_organization_iam_member" "cloud_function_roles" {
  for_each = toset(local.cloud_function.org_permissions)

  org_id = var.organization_id
  role   = each.value
  member = "serviceAccount:${module.cloud_function_sa.email}"
}

