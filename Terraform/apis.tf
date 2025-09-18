resource "google_project_service" "project" {
  for_each = toset(local.enabled_apis)
  project  = var.project_id
  service  = each.value
  disable_on_destroy = false
  disable_dependent_services = false
}