
data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "${path.module}/../../code"
  output_path = "${path.module}/../../function-source.zip"
}
