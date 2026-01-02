# # =============================================================================
# # Cyngular GCP Client Onboarding Configuration
# # =============================================================================
# # This file contains the configuration for onboarding a client to Cyngular.
# # See README-2.md for detailed documentation.

# # -----------------------------------------------------------------------------
# # REQUIRED: Client & GCP Organization Settings
# # -----------------------------------------------------------------------------

# # GCP organization ID where the client resources will be deployed
# # Find via: gcloud organizations list
# organization_id = "1111111111111111111"

# # GCP billing account ID (format: XXXXXX-YYYYYY-ZZZZZZ)
# # Find via: gcloud billing accounts list
# billing_account = "XXXXXX-YYYYYY-ZZZZZZ"

# # Client identifier (lowercase letters and numbers only, no hyphens/underscores)
# # This will be used in resource names: cyngular-{client_name}
# client_name = "acme"

# # Primary GCP region for client resources (e.g., us-central1, us-east4, europe-west1)
# client_main_location = "us-central1"

# # Cyngular environment project number - determines dev or prod deployment
# # Dev:  248189932415 (cyngular-dev)  - For testing/development clients
# # Prod: 839416416471 (cyngular-prod) - For production clients (default)
# # cyngular_project_number = "839416416471"  # Uncomment to override default

# # -----------------------------------------------------------------------------
# # OPTIONAL: Organization-Wide Audit Logging Configuration
# # -----------------------------------------------------------------------------
# # Configures organization-level audit logs and BigQuery export for security monitoring.
# # If omitted entirely, no audit logging will be configured.
# #
# # Note: Audit log types have different volume/cost implications:
# #   - ADMIN_READ: Low volume, recommended for compliance (admin/config operations)
# #   - DATA_READ: HIGH volume, can be expensive (data access operations) - enable only if needed
# #   - DATA_WRITE: Medium volume, recommended for security monitoring (data modifications)

# organization_audit_logs = {
#   # Which audit log types to enable at the organization level
#   log_configuration = {
#     "ADMIN_READ" = true   # RECOMMENDED: Track admin operations (low cost)
#     "DATA_READ"  = false  # CAUTION: High volume, expensive - only enable if required
#     "DATA_WRITE" = true   # RECOMMENDED: Track data modifications (moderate cost)
#   }
# }

# # -----------------------------------------------------------------------------
# # OPTIONAL: Use Existing BigQuery Dataset
# # -----------------------------------------------------------------------------
# # If you want to use an existing BigQuery dataset instead of creating a new one,
# # uncomment and configure the following. If omitted (null), a new dataset will be
# # created in the Cyngular project with the name: {client_name}_cyngular_sink
#
# existing_bigquery_dataset = {
#   dataset_name = "existing_audit_logs"     # Required: Name of the existing dataset
#   project_id   = "shared-logging-project"  # Required: Project ID containing the dataset
#   location     = "us-east4"                # Optional: Defaults to client_main_location if omitted
# }

# # cloud_function = {
# #   env_vars = {
# #     "PROJECT_ID" = "acme-cyngular"      # This will match the project created by Terraform
# #     "DATASET_ID" = "acme_cyngular_sink" # This will match the dataset from organization_audit_logs
# #     "LOCATION"   = "us-central1"        # Same as cloud function location
# #   }
# # }

# # cyngular_sa_base_email = "SA_NAME@PROJECT_ID.iam.gserviceaccount.com"
# # cyngukar_project_id = "acme-project"
