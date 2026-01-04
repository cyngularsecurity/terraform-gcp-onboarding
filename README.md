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

- **Terraform** - ([Installation Guide](https://developer.hashicorp.com/terraform/install))
- **gcloud CLI** - ([Installation Guide](https://cloud.google.com/sdk/docs/install))
<!-- - **uv**: Latest version ([Installation Guide](https://astral.sh/uv/install)) -->

Verify installations:

```bash
terraform -v
gcloud version
```

### Required GCP Permissions

The user or service account running Terraform **must** have these organization-level IAM roles:

| Role | Permission | Info |
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

For detailed permission setup instructions, see [SETUP_PERMISSION.md](./docs/SETUP_PERMISSION.md).

### GCP Authentication

Authenticate using Application Default Credentials:

```bash
gcloud auth login

# Set auth as local config
gcloud auth application-default login
```

## Quick Start

### 1. Use module

create a main.tf file:

```hcl
module "cyngular_gcp_onboarding" {
  source  = "cyngularsecurity/onboarding/gcp"

  client_name     = "acme"
  client_main_location = "us-central1"

  organization_id = "1234567890123"
  billing_account = "XXXXXX-YYYYYY-ZZZZZZ"

  organization_audit_logs = {
    log_configuration = {
      "ADMIN_READ" = true
      "DATA_READ"  = false
      "DATA_WRITE" = true
    }
  }
}

output "deployment_summary" {
  value = module.cyngular_gcp_onboarding.deployment_summary
}
```

### 2. Initialize and Deploy

```bash
# Initialize Terraform modules
terraform init

terraform plan
# Review planned changes

# Apply configuration
terraform apply --auto-approve
```

### 3. Verify Deployment

```bash
# Cyngular project
gcloud projects describe cyngular-<client_name>

# Cloud Function
gcloud functions list --project=cyngular-<client_name>

# BigQuery dataset
bq ls --project_id=cyngular-<client_name> / existing
```

## Input Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `client_name` | `string` | Client Company name (lowercase letters and numbers only, see other constraints) |
| `client_main_location` | `string` | Primary GCP region code for client resources (e.g., `us-central1`) |
| `organization_id` | `string` | GCP organization ID where resources will be deployed |
| `billing_account` | `string` | GCP billing account ID (format: `XXXXXX-YYYYYY-ZZZZZZ`) |
| `organization_audit_logs` | `object` | Organization audit log configuration |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cyngular_project_folder_id` | `string` | `""` | GCP folder ID to create project under. Creates under organization if empty |
| `existing_bigquery_dataset` | `object` | `null` | **Optional**: Configuration for using an existing BigQuery dataset instead of creating a new one. If null, a new dataset will be created in the Cyngular project. See configuration details below. |

### organization_audit_logs Configuration

```hcl
organization_audit_logs = {
  # Which audit log types to enable
  log_configuration = {
    "ADMIN_READ" = bool  # Admin activity logs
    "DATA_READ"  = bool  # Data access read logs
    "DATA_WRITE" = bool  # Data access write logs
  }
}
```

### existing_bigquery_dataset Configuration

```hcl
existing_bigquery_dataset = {
  dataset_name = string  # Required: Name of the existing BigQuery dataset
  project_id   = string  # Required: GCP project ID containing the dataset
  location     = string  # Optional: Dataset location (defaults to client_main_location if omitted)
}
```

**Note**: If `existing_bigquery_dataset` is `null` (default), a new BigQuery dataset will be created in the Cyngular project with the name `{client_name}_cyngular_sink`.

## Examples

### Standard

```hcl
client_name     = "acme"
client_main_location = "us-central1"

organization_id = "1234567890123"
billing_account = "XXXXXX-YYYYYY-ZZZZZZ"

organization_audit_logs = {
  log_configuration = {
    "ADMIN_READ" = true
    "DATA_READ"  = false
    "DATA_WRITE" = true
  }
}
```

### Using Existing BigQuery Dataset

```hcl
client_name     = "acme"
client_main_location = "us-east4"

organization_id = "1234567890123"
billing_account = "XXXXXX-YYYYYY-ZZZZZZ"


# Use an existing BigQuery dataset
existing_bigquery_dataset = {
  dataset_name = "existing_audit_logs"
  project_id   = "cyngular-acme"
  location     = "us-east4"  # Optional
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
    prefix = "some/path/cyngular-onboarding"
  }
}
```

Then initialize:

```bash
# Initialize providers and backend
terraform init -upgrade

# Inspect what Terraform will change
terraform plan

terraform apply --auto-approve
```

## Troubleshooting

See [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) for common issues and solutions.

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

1. Check [SETUP_PERMISSION.md](./docs/SETUP_PERMISSION.md) for permission-related problems
2. Review the [Troubleshooting](./docs/TROUBLESHOOTING.md) guide
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
