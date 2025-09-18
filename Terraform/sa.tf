module "cyngular_sa" {
  depends_on = [
    module.project
  ]
  source        = "terraform-google-modules/service-accounts/google"
  version       = "~> 4.0"
  project_id    = local.project_config.project_id
  names         = ["cyngular-sa"]
  project_roles = local.cyngular_sa_permissions
}

resource "google_organization_iam_member" "cyngular_sa_roles" {
  depends_on = [
    module.project,
    google_organization_iam_custom_role.cyngular_custom
  ]
  for_each = toset(local.cyngular_sa.org_permissions)
  org_id   = var.organization_id
  role     = each.value
  member   = "serviceAccount:${module.cyngular_sa.email}"
}

resource "google_organization_iam_member" "cyngular_sa_org_conditional_role" {
  depends_on = [
    google_organization_iam_custom_role.cyngular_custom
  ]
  org_id   = var.organization_id
  role     = "organizations/${var.organization_id}/roles/${local.cyngular_org_role.name}"
  member   = "serviceAccount:${module.cyngular_sa.email}"

  condition {
    title       = "Cyngular Snapshot condition"
    description = "Used to limit permissions only to specific snapshots when operations are on snapshots"
    expression  = "resource.type != 'compute.googleapis.com/Snapshot' || resource.name.extract('/global/snapshots/{name}').startsWith('cyngular')"
  }
}
resource "google_service_account_iam_member" "cyngular_sa" {
  depends_on         = [module.project]
  service_account_id = module.cyngular_sa.service_account.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${local.cyngular_sa.base_sa_email}"
}