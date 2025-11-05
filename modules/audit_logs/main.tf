resource "google_organization_iam_audit_config" "organization" {
  count   = var.audit_log_configuration != null && try(var.audit_log_configuration.enable_admin_read || var.audit_log_configuration.enable_data_read || var.audit_log_configuration.enable_data_write, false) ? 1 : 0
  org_id  = var.org_id
  service = "allServices"
  dynamic "audit_log_config" {
    for_each = try(var.audit_log_configuration.enable_admin_read, false) ? [1] : []
    content {
      log_type = "ADMIN_READ"
    }
  }
  dynamic "audit_log_config" {
    for_each = try(var.audit_log_configuration.enable_data_read, false) ? [1] : []
    content {
      log_type = "DATA_READ"
    }
  }
  dynamic "audit_log_config" {
    for_each = try(var.audit_log_configuration.enable_data_write, false) ? [1] : []
    content {
      log_type = "DATA_WRITE"
    }
  }
}

