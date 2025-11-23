# Cyngular GCP Client Onboarding

Terraform module for automated client onboarding in Google Cloud Platform. This module provisions a dedicated GCP project with organization-wide audit logging, BigQuery export, and Cloud Functions for security monitoring.

## Features

- **Automated Project Creation**: Creates a dedicated GCP project for Cyngular with proper billing configuration
- **Organization Audit Logs**: Configures organization-level audit log collection with optional BigQuery export
- **Service Accounts**: Provisions service accounts with least-privilege IAM roles for monitoring and data processing
- **Cloud Function**: Deploys a Python Cloud Function for automated audit log processing
- **Cross-Project Snapshots**: Enables GKE CSI driver to access disk snapshots across projects
- **Custom IAM Roles**: Creates organization-level custom roles for snapshot management

## Architecture

```
Organization
├── Audit Log Sink → BigQuery Dataset
├── Custom IAM Role (cyngularOrgRole)
└── Cyngular Project
    ├── Service Accounts (cyngular-sa, cyngular-cf-sa, cloud-build-sa)
    ├── Cloud Function (audit log processor)
    ├── BigQuery Dataset (optional)
    └── Storage Bucket (Cloud Function source)
```

## Prerequisites

### Required Tools

- **Terraform**: v1.0 or later ([Installation Guide](https://developer.hashicorp.com/terraform/install))
- **gcloud CLI**: Latest version ([Installation Guide](https://cloud.google.com/sdk/docs/install))

Verify installations:
```bash
terraform -v
gcloud version
```

### Required GCP Permissions

The user or service account running Terraform **must** have these organization-level IAM roles:

| Role | Permission | Purpose |
|------|------------|---------|
| **Organization Administrator** | `roles/resourcemanager.organizationAdmin` | Create organization IAM bindings |
| **Organization Role Administrator** | `roles/iam.organizationRoleAdmin` | Create custom roles at org level |
| **Project Creator** | `roles/resourcemanager.projectCreator` | Create new projects |

**Grant permissions via gcloud CLI:**
```bash
ORG_ID="YOUR_ORG_ID"
USER_EMAIL="user@example.com"

gcloud organizations add-iam-policy-binding ${ORG_ID} \
  --member="user:${USER_EMAIL}" \
  --role="roles/resourcemanager.organizationAdmin"

gcloud organizations add-iam-policy-binding ${ORG_ID} \
  --member="user:${USER_EMAIL}" \
  --role="roles/iam.organizationRoleAdmin"

gcloud organizations add-iam-policy-binding ${ORG_ID} \
  --member="user:${USER_EMAIL}" \
  --role="roles/resourcemanager.projectCreator"
```

For detailed permission setup instructions, see [MANUAL_PERMISSION_SETUP.md](./MANUAL_PERMISSION_SETUP.md).

### GCP Authentication

Authenticate using Application Default Credentials:

```bash
# Authenticate for gcloud CLI commands (optional)
gcloud auth login

# Authenticate for Terraform and other tools (required)
gcloud auth application-default login

# Set default project (optional)
gcloud config set project YOUR_PROJECT_ID
```

## Quick Start

### 1. Configure Variables

Copy the example tfvars file and fill in your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
organization_id = "1234567890123"
billing_account = "XXXXXX-YYYYYY-ZZZZZZ"
client_name     = "acme"
client_main_region = "us-central1"

organization_audit_logs = {
  log_configuration = {
    enable_admin_read = true
    enable_data_read  = false
    enable_data_write = true
  }
  enable_bigquery_export = true
  bq_location            = "us-east4"
}

# Only needed if you want to override the default
# cyngular_project_number = "248189932415"  # Dev: 248189932415, Prod: 839416416471
```

### 2. Initialize and Deploy

```bash
# Initialize Terraform providers
terraform init

# Review planned changes
terraform plan

# Apply configuration
terraform apply
```

### 3. Verify Deployment

```bash
# Check created project
gcloud projects describe cyngular-<client_name>

# Verify Cloud Function deployed
gcloud functions list --project=cyngular-<client_name>

# Check BigQuery dataset
bq ls --project_id=cyngular-<client_name>
```

## Input Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `client_name` | `string` | Client organization name (lowercase letters and numbers only) |
| `client_main_region` | `string` | Primary GCP region for client resources (e.g., `us-central1`) |
| `organization_id` | `string` | GCP organization ID where resources will be deployed |
| `billing_account` | `string` | GCP billing account ID (format: `XXXXXX-YYYYYY-ZZZZZZ`) |
| `organization_audit_logs` | `object` | Organization audit log configuration |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cyngular_project_id` | `string` | `""` | Custom project ID. Defaults to `cyngular-{client_name}` if empty |
| `cyngular_project_folder_id` | `string` | `""` | GCP folder ID to create project under. Creates under organization if empty |
| `cyngular_project_number` | `string` | `"839416416471"` | Cyngular project number for GKE CSI cross-project snapshot access |
| `cyngular_sa_base_email` | `string` | `""` | **DEPRECATED**: Auto-generated from client_name and environment |

### organization_audit_logs Configuration

```hcl
organization_audit_logs = {
  # Which audit log types to enable
  log_configuration = {
    enable_admin_read = bool  # Admin activity logs (recommended: true)
    enable_data_read  = bool  # Data access read logs (high volume)
    enable_data_write = bool  # Data access write logs (recommended: true)
  }

  # BigQuery export settings
  enable_bigquery_export = bool    # Create new dataset (true) or use existing (false)
  bq_location            = string  # BigQuery region (default: "us-east4")

  # Required if enable_bigquery_export = false
  existing_bq_dataset = {
    dataset_id = string  # Existing BigQuery dataset ID
    project_id = string  # Project containing the dataset
  }
}
```

## Examples

### Minimal Configuration (New BigQuery Dataset)

```hcl
organization_id = "1234567890123"
billing_account = "XXXXXX-YYYYYY-ZZZZZZ"
client_name     = "acme"
client_main_region = "us-central1"

organization_audit_logs = {
  log_configuration = {
    enable_admin_read = true
    enable_data_read  = false
    enable_data_write = true
  }
  enable_bigquery_export = true
}
```

### Using Existing BigQuery Dataset

```hcl
organization_id = "1234567890123"
billing_account = "XXXXXX-YYYYYY-ZZZZZZ"
client_name     = "acme"
client_main_region = "us-east4"

organization_audit_logs = {
  log_configuration = {
    enable_admin_read = true
    enable_data_read  = false
    enable_data_write = true
  }
  enable_bigquery_export = false
  existing_bq_dataset = {
    dataset_id = "existing_audit_logs"
    project_id = "shared-logging-project"
  }
}
```

### Custom Project Settings

```hcl
organization_id         = "1234567890123"
billing_account         = "XXXXXX-YYYYYY-ZZZZZZ"
client_name             = "acme"
client_main_region      = "europe-west1"
cyngular_project_id     = "custom-acme-security"
cyngular_project_folder_id = "folders/123456789"

organization_audit_logs = {
  log_configuration = {
    enable_admin_read = true
    enable_data_read  = true
    enable_data_write = true
  }
  enable_bigquery_export = true
  bq_location            = "EU"
}
```

### Development Environment

```hcl
organization_id         = "1234567890123"
billing_account         = "XXXXXX-YYYYYY-ZZZZZZ"
client_name             = "acmedev"
client_main_region      = "us-central1"
cyngular_project_number = "248189932415"  # Dev environment project number

organization_audit_logs = {
  log_configuration = {
    enable_admin_read = true
    enable_data_read  = false
    enable_data_write = false
  }
  enable_bigquery_export = true
}
```

## Outputs

This module creates the following resources (outputs can be added to `outputs.tf`):

- **GCP Project**: `cyngular-{client_name}`
- **Service Accounts**:
  - `cyngular-sa@cyngular-{client_name}.iam.gserviceaccount.com`
  - `cyngular-cf-sa@cyngular-{client_name}.iam.gserviceaccount.com`
  - `cyngular-cloud-build-sa@cyngular-{client_name}.iam.gserviceaccount.com`
- **Cloud Function**: `cyngular-function`
- **BigQuery Dataset**: `{client_name}_cyngular_sink` (if enabled)
- **Custom IAM Role**: `organizations/{org_id}/roles/cyngularOrgRole`

## Remote State Backend

For team collaboration, configure a remote backend. Create a `backend.tf` file:

```hcl
terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "cyngular/clients/{client_name}"
  }
}
```

Then initialize:
```bash
terraform init -reconfigure
```

## Troubleshooting

### Permission Errors (403)

**Symptom**: `Error 403: The caller does not have permission`

**Solution**: Ensure you have the required organization-level roles. See [MANUAL_PERMISSION_SETUP.md](./MANUAL_PERMISSION_SETUP.md).

### Custom Role Already Exists

**Symptom**: `Custom role already exists and must be imported`

**Solution**: Import existing resources:
```bash
terraform import google_organization_iam_custom_role.cyngular_custom \
  organizations/{ORG_ID}/roles/cyngularOrgRole
```

### Project Already Exists

**Symptom**: `Project {project_id} already exists`

**Solution**: Import existing project:
```bash
terraform import google_project.cyngular_project {project_id}
```

### Cloud Function Fails to Deploy

**Symptom**: Cloud Function creation timeout or errors

**Solution**:
1. Verify Cloud Functions API is enabled
2. Check service account permissions
3. Review Cloud Build logs for build errors

### Client Name Validation Error

**Symptom**: `client_name must contain only lowercase letters and numbers`

**Solution**: Use only lowercase letters (a-z) and numbers (0-9). No hyphens, underscores, or uppercase letters.

## Important Notes

- **Client Naming**: The `client_name` must contain only lowercase letters and numbers (no hyphens or special characters)
- **Environment Detection**: Environment (dev/prod) is auto-detected based on `cyngular_project_number`
- **API Enablement**: The module automatically enables required GCP APIs (BigQuery, Cloud Functions, Compute, etc.)
- **Audit Log Types**: Enable only necessary audit log types to control costs (Data Read logs can be expensive)
- **Snapshot Permissions**: The module grants Cyngular's GKE CSI driver read-only access to client disk snapshots
- **Deployment Time**: Initial deployment takes 3-5 minutes. Cloud Function may take an additional 60 seconds to become fully available

## Security Considerations

- All service accounts follow the principle of least privilege
- Custom IAM roles are scoped to specific resource types (snapshots)
- Conditional IAM bindings restrict snapshot operations to Cyngular-prefixed resources only
- No permanent credentials are stored in the module
- Service account impersonation is used for cross-project access

## Module Structure

```
.
├── README.md                    # This file
├── MANUAL_PERMISSION_SETUP.md   # Detailed permission setup guide
├── variables.tf                 # Input variable definitions
├── locals.tf                    # Local values and configuration
├── main.tf                      # Project creation
├── apis.tf                      # API enablement
├── iam.tf                       # Custom IAM roles
├── sa.tf                        # Service account creation
├── audit-logs.tf                # Audit log sink configuration
├── cloud-function.tf            # Cloud Function deployment
├── terraform.tfvars.example     # Example variable values
├── Providers.tf                 # Provider configuration
├── code/                        # Cloud Function source code
│   ├── main.py
│   └── requirements.txt
└── modules/
    └── audit_logs/              # Audit logs submodule
        ├── main.tf
        ├── variables.tf
        ├── bq.tf
        └── iam.tf
```

## Support

For issues or questions:

1. Check [MANUAL_PERMISSION_SETUP.md](./MANUAL_PERMISSION_SETUP.md) for permission-related problems
2. Review the [Troubleshooting](#troubleshooting) section
3. Verify all prerequisites are met
4. Contact the Cyngular infrastructure team

## Version Requirements

- **Terraform**: >= 1.0
- **Google Provider**: 5.45.2
- **Google Beta Provider**: 5.45.2
- **Archive Provider**: 2.7.1

## License

Internal use only - Cyngular Security


graph TD
    A[Start] --> B[GCP Organization Access]
    B --> C[Terraform Install + gcloud Setup]
    C --> D[Configure Module Inputs]
    D --> E[Run terraform init]
    E --> F[Run terraform plan]
    F --> G[Run terraform apply]
    G --> H[Verify in GCP + Cyngular]
    H --> I[Optional Labeling and Tagging]
    I --> J[End]