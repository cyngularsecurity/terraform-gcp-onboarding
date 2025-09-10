module "project" {
  source   = "terraform-google-modules/project-factory/google"
  version  = "~> 17.0"

  activate_apis           = local.project_config.apis
  random_project_id       = false
  auto_create_network     = false
  name                    = local.project_config.project_id
  project_id              = local.project_config.project_id
  org_id                  = var.organization_id
  billing_account         = var.billing_account
  folder_id               = try(local.project_config.folder_id,null) != null ? local.project_config.folder_id : ""
  default_service_account = "deprivilege"
  default_network_tier    = "PREMIUM"
}
