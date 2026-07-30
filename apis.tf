resource "google_project_service" "project" {
  for_each                   = toset(local.enabled_apis)
  project                    = local.cyngular_project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false

  depends_on = [google_project.cyngular_project]
}

# Enable org-wide discovery APIs on every active project under the organization,
# so Cyngular's asset/resource-manager access works across all client projects.
# NOTE: google_projects only returns projects whose direct parent is the org node;
# projects nested inside folders are NOT included by this filter.
data "google_projects" "org_projects" {
  filter = "parent.id:${var.organization_id} lifecycleState:ACTIVE"
}

locals {
  all_projects_apis = [
    "cloudasset.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ]

  org_project_api_pairs = {
    for pair in setproduct(data.google_projects.org_projects.projects[*].project_id, local.all_projects_apis) :
    "${pair[0]}::${pair[1]}" => { project = pair[0], service = pair[1] }
  }
}

resource "google_project_service" "org_projects_apis" {
  for_each = local.org_project_api_pairs

  project                    = each.value.project
  service                    = each.value.service
  disable_on_destroy         = false
  disable_dependent_services = false
}
