resource "terraform_data" "wait_for_build_sa_permissions" {
  provisioner "local-exec" {
    command = <<EOT
      for i in {1..60}; do
        echo "Checking permissions for ${module.cloud_build_sa.email} (Attempt $i)..."
        if gcloud projects get-iam-policy ${var.cyngular_project_id} --flatten="bindings[].members" --format="json" | grep -q "serviceAccount:${module.cloud_build_sa.email}"; then
          echo "Permissions propagated!"
          exit 0
        fi
        sleep 2
      done
      echo "Timeout waiting for permissions propagation"
      exit 1
    EOT
  }

  depends_on = [
    module.cloud_build_sa
  ]
}

resource "terraform_data" "call_cloud_function" {
  provisioner "local-exec" {
    command = "sleep 60 && curl -H \"Authorization: Bearer $(gcloud auth print-identity-token)\" ${module.cloud_function.function_uri}"
  }

  depends_on = [
    module.cloud_function,
  ]
}
