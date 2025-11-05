resource "google_project_service" "project" {
  for_each                   = toset(local.enabled_apis)
  project                    = local.cyngular_project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false

  depends_on = [google_project.cyngular_project]
}
