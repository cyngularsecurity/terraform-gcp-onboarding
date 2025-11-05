resource "google_organization_iam_custom_role" "cyngular_custom" {
  depends_on  = [google_project_service.project]
  role_id     = local.cyngular_org_role.name
  org_id      = var.organization_id
  title       = "Cyngular Org Role"
  description = "Used to access resources within the organization by Cyngular"
  permissions = local.cyngular_org_role.permissions
}

resource "google_project_iam_custom_role" "gke_csi_snapshot_reader" {
  project     = local.cyngular_project_id
  role_id     = local.gke_csi_snapshot.custom_role.role_id
  title       = local.gke_csi_snapshot.custom_role.title
  description = local.gke_csi_snapshot.custom_role.description

  permissions = local.gke_csi_snapshot.custom_role.permissions
}

resource "google_project_iam_member" "gke_csi_snapshot_service_account" {
  project = local.cyngular_project_id
  role    = google_project_iam_custom_role.gke_csi_snapshot_reader.id
  member  = "serviceAccount:service-${var.cyngular_project_number}@container-engine-robot.iam.gserviceaccount.com"
}