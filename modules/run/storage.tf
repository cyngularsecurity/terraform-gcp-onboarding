resource "google_storage_bucket" "gcf_source" {
  name     = "${var.cyngular_project_id}-gcf-source"
  location = var.bucket_location
  project  = var.cyngular_project_id

  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "function_source" {
  name   = "function-source-${data.archive_file.function_source.output_md5}.zip"
  bucket = google_storage_bucket.gcf_source.name
  source = data.archive_file.function_source.output_path
}
