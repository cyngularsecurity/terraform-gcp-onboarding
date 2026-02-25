# Client Service Account Permissions

This document details all permissions granted to the Cyngular client service account (`cyngular-sa`). This is the main service account used by Cyngular to access and monitor client resources.

> **Note**: This document covers only the client service account (`cyngular-sa`), not the Cloud Run function service account (`cyngular-cf-sa`) or Cloud Build service account.

## Service Account Overview

| Property | Value |
|----------|-------|
| **Name** | `cyngular-sa` |
| **Email** | `cyngular-sa@{project_id}.iam.gserviceaccount.com` |
| **Created In** | Cyngular client project (`{project_id}`) |
| **Purpose** | Primary service account for Cyngular to access and monitor client organization resources |

---

## Organization-Level Permissions

These permissions are granted at the organization level and apply to all projects within the organization.

### Built-in Roles

| Role | Description | Source File |
|------|-------------|-------------|
| `roles/viewer` | Read-only access to all organization resources. Allows viewing resources and their configurations across the entire organization. | `sa.tf:15-25` |
| `roles/browser` | Permission to browse the resource hierarchy (folders, projects). Enables navigation of the organization structure. | `sa.tf:15-25` |

### Custom Organization Role

A custom role is created at the organization level with conditional permissions for snapshot management.

| Custom Role | Description | Source File |
|-------------|-------------|-------------|
| `organizations/{org_id}/roles/cyngular_org_role_{client_name}` | Snapshot management role with conditional access | `iam.tf:1-10` |

#### Custom Role Permissions

| Permission | Description |
|------------|-------------|
| `compute.disks.createSnapshot` | Create snapshots from compute disks |
| `compute.snapshots.create` | Create new snapshots |
| `compute.snapshots.getIamPolicy` | Read IAM policy on snapshots |
| `compute.snapshots.setIamPolicy` | Modify IAM policy on snapshots |
| `compute.snapshots.useReadOnly` | Use snapshots in read-only mode |
| `compute.snapshots.get` | View snapshot information |
| `compute.snapshots.delete` | Delete snapshots |
| `compute.snapshots.list` | List all snapshots |

#### IAM Condition

The custom role is bound with a **conditional IAM binding** that restricts operations to Cyngular-prefixed snapshots only:

```cel
resource.type != 'compute.googleapis.com/Snapshot' || resource.name.extract('/global/snapshots/{name}').startsWith('cyngular')
```

**Effect**: This ensures the service account can only perform snapshot operations on snapshots whose names start with `cyngular`. Operations on non-snapshot resources are unaffected by this condition.

---

## Project-Level Permissions

These permissions are granted on the Cyngular project only.

### Built-in Roles

| Role | Description | Scope | Source File |
|------|-------------|-------|-------------|
| `roles/run.invoker` | Invoke Cloud Run services. Allows triggering the Cyngular Cloud Function. | Cyngular project | `locals.tf:60-63`, `sa.tf:1-13` |
| `roles/bigquery.jobUser` | Create and run BigQuery jobs. Required for querying audit log data. | Cyngular project | `locals.tf:60-63`, `sa.tf:1-13` |

---

## BigQuery Dataset-Level Permissions

These permissions are granted on the audit logs BigQuery dataset.

| Role | Description | Dataset | Source File |
|------|-------------|---------|-------------|
| `roles/bigquery.dataEditor` | Read, write, and modify data in the BigQuery dataset. Allows processing and managing audit log data. | `{client_name}_cyngular_sink` or existing dataset | `modules/audit_logs/iam.tf:1-12`, `modules/audit_logs/locals.tf:9-11` |

---

## Service Account Impersonation

The Cyngular base service account (from the Cyngular environment project) is granted permission to impersonate this client service account.

| Principal | Role | Target | Source File |
|-----------|------|--------|-------------|
| `{client_name}@cyngular-{env}.iam.gserviceaccount.com` | `roles/iam.serviceAccountTokenCreator` | `cyngular-sa@cyngular-{client_name}.iam.gserviceaccount.com` | `sa.tf:43-47` |

This enables:

- Cross-project access from Cyngular's infrastructure to client resources
- Token generation for secure service-to-service authentication
- Impersonation-based access without storing credentials

---

## Permission Summary by Scope

### Organization Scope (All Projects)

| Type | Role/Permission | Access Level |
|------|-----------------|--------------|
| Built-in | `roles/viewer` | Read-only to all resources |
| Built-in | `roles/browser` | Browse resource hierarchy |
| Custom | Snapshot operations | Create/Read/Delete (cyngular-prefixed only) |

### Project Scope (Cyngular Project Only)

| Type | Role | Access Level |
|------|------|--------------|
| Built-in | `roles/run.invoker` | Invoke Cloud Run |
| Built-in | `roles/bigquery.jobUser` | Run BigQuery jobs |

### Dataset Scope (Audit Logs Dataset)

| Type | Role | Access Level |
|------|------|--------------|
| Built-in | `roles/bigquery.dataEditor` | Read/Write data |

---

## Security Considerations

1. **Least Privilege**: Permissions are scoped to the minimum required for Cyngular monitoring functionality.

2. **Conditional Bindings**: Snapshot operations are restricted to Cyngular-prefixed resources only, preventing accidental or unauthorized operations on client snapshots.

3. **Service Account Impersonation**: Uses Google's recommended approach for cross-project access, avoiding long-lived credentials.

4. **Read-Heavy Access**: The majority of permissions are read-only (`roles/viewer`, `roles/browser`), with write access limited to:
   - Cyngular-prefixed snapshots
   - Audit logs BigQuery dataset

---

## Code References

| Resource | File | Lines |
|----------|------|-------|
| Service Account Creation | `sa.tf` | 1-13 |
| Org-level Role Bindings | `sa.tf` | 15-41 |
| SA Impersonation | `sa.tf` | 43-47 |
| Custom Org Role | `iam.tf` | 1-10 |
| Permission Definitions | `locals.tf` | 45-68 |
| BigQuery Dataset Permissions | `modules/audit_logs/iam.tf` | 1-12 |
| BigQuery SA Permissions | `modules/audit_logs/locals.tf` | 9-11 |

---

## Related Documentation

- [Setup Permissions](./SETUP_PERMISSION.md) - Permissions required to deploy this module
- [Troubleshooting](./TROUBLESHOOTING.md) - Common issues and solutions