module "service_account_permissions" {
  source = "./Modules/IAM"
  client_project_id = var.client_project_id
  source_org_service_account_email = var.source_org_service_account_email
  client_region = var.client_region
  # cyngular_access_roles = var.cyngular_access_roles
}

# # If you need to restrict access to specific resources, use more granular permissions
# resource "google_storage_bucket_iam_member" "bucket_access" {
#   bucket = google_storage_bucket.shared_bucket.name
#   role   = "roles/storage.objectViewer"
#   member = "serviceAccount:${var.source_org_service_account_email}"
# }

# # Example shared resource
# resource "google_storage_bucket" "shared_bucket" {
#   name     = "cross-org-shared-bucket-${var.client_project_id}"
#   location = var.client_region
# }