data "google_project" "existing_project" {
  count      = var.existing_project_id != null ? 1 : 0
  project_id = var.existing_project_id
}