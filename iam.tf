resource "google_organization_iam_custom_role" "cyngular_custom" {
  depends_on = [ google_project_service.project ]
  role_id     = local.cyngular_org_role.name
  org_id      = var.organization_id
  title       = "Cyngular Org Role"
  description = "Used to access resources within the organization by Cyngular"
  permissions = local.cyngular_org_role.permissions
}