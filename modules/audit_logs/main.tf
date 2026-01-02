# Configures organization-wide audit logging for security monitoring
# This resource is OPTIONAL - only created if log_configuration is provided
#
# Audit log types:
#   - ADMIN_READ: Admin/configuration reads (low volume, recommended for compliance)
#   - DATA_READ: Data access operations (HIGH volume, can be expensive - enable only if needed)
#   - DATA_WRITE: Data modification operations (medium volume, recommended for security monitoring)
resource "google_organization_iam_audit_config" "organization" {
  count   = length([for k, v in var.audit_log_configuration : k if v]) > 0 ? 1 : 0

  org_id  = var.org_id
  service = "allServices"

  dynamic "audit_log_config" {
    for_each = { for k, v in var.audit_log_configuration : k => v if v }
    content {
      log_type = audit_log_config.key
    }
  }
}

