
# Grant the Organization 1 service account access to specific resources
resource "google_project_iam_member" "roles" {
  project = var.client_project_id
  member  = "serviceAccount:${var.source_org_service_account_email}"

  # for_each = toset(local.cyngular_access_roles)
  # role     = each.value
  # role     = google_project_iam_custom_role.cyngular_readonly_role.role_id
  role     = "projects/${var.client_project_id}/roles/${google_project_iam_custom_role.cyngular_readonly_role.role_id}"
}

resource "google_project_iam_custom_role" "cyngular_readonly_role" {
  role_id     = "CyngularReadOnlyRole"
  title       = "Cyngular ReadOnly Role"
  description = "Cyngular ReadOnly Role"
  permissions = local.cyngular_access_permissions
}