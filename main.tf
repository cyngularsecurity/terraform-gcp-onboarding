resource "google_project" "cyngular_project" {
  project_id          = local.cyngular_project_id
  org_id              = var.organization_id
  name                = "cyngular ${var.client_name}"
  billing_account     = var.billing_account
  auto_create_network = false
  deletion_policy     = "DELETE"
  folder_id           = var.cyngular_project_folder_id != "" ? var.cyngular_project_folder_id : null
}
