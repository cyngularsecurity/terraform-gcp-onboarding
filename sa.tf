module "cyngular_sa" {
  source        = "terraform-google-modules/service-accounts/google"
  version       = "~> 4.0"
  # version = "4.6.0" // with latest google tf provider version

  project_id    = local.cyngular_project_id
  names         = ["cyngular-sa"]
  project_roles = local.cyngular_sa_permissions

  depends_on = [
    google_project.cyngular_project
  ]
}

resource "google_organization_iam_member" "cyngular_sa_roles" {
  for_each = toset(local.cyngular_sa.org_permissions)

  org_id = var.organization_id
  role   = each.value
  member = "serviceAccount:${module.cyngular_sa.email}"

  # depends_on = [
  #   google_organization_iam_custom_role.cyngular_custom
  # ]
}

resource "google_organization_iam_member" "cyngular_sa_org_conditional_role" {
  org_id = var.organization_id
  role   = "organizations/${var.organization_id}/roles/${local.cyngular_org_role.name}"
  member = "serviceAccount:${module.cyngular_sa.email}"

  condition {
    title       = "Cyngular Snapshot condition"
    description = "Used to limit permissions only to specific snapshots when operations are on snapshots"
    expression  = "resource.type != 'compute.googleapis.com/Snapshot' || resource.name.extract('/global/snapshots/{name}').startsWith('cyngular')"
  }

  depends_on = [
    google_organization_iam_custom_role.cyngular_custom
  ]
}

resource "google_service_account_iam_member" "cyngular_sa" {
  service_account_id = module.cyngular_sa.service_account.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${local.cyngular_sa_base_email}"
}
