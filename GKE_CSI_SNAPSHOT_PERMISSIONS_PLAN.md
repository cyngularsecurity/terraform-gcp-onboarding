# GKE CSI Driver Snapshot Read Permissions - Implementation Plan

## Problem Statement

The OS service pods in GKE clusters cannot create VolumeSnapshotContent objects from snapshots in client projects, failing with:

```
Error 403: Required 'compute.snapshots.get' permission for 'projects/zippy-catwalk-468816-n0/global/snapshots/snap-*', forbidden
```

### Root Cause

The GKE Persistent Disk CSI driver requires **project-level IAM permissions** in the source project (client project) to validate cross-project snapshots, even when snapshots are shared via resource-level IAM policies.

**Technical Details:**
- Snapshot is in client project: `zippy-catwalk-468816-n0`
- GKE cluster is in Cyngular project: `cyngular-dev`
- CSI driver runs on GKE nodes using **node service accounts**
- Node SAs need project-level `compute.snapshots.get` permission to validate snapshots exist
- Resource-level IAM alone is insufficient for CSI driver validation logic

**Reference**: [Stack Overflow - Cross-project VolumeSnapshotContent](https://stackoverflow.com/questions/71401050/create-a-volumesnapshotcontent-using-a-snapshot-handle-from-another-gcp-project)

## Solution

Grant minimal snapshot read permissions to **GKE node service accounts** in client projects during onboarding.

### Architecture: How GKE CSI Driver Works

1. **CSI Driver Location**: Runs as DaemonSet pods on GKE cluster nodes
2. **Authentication**: Uses the **node service account** attached to the GKE nodes
3. **Default Node SA**: `<PROJECT_NUMBER>-compute@developer.gserviceaccount.com` (Compute Engine default)
4. **Custom Node SA**: Can be specified per node pool (e.g., `tf-gke-dev-gke-us-east-msra@cyngular-dev.iam.gserviceaccount.com`)
5. **Permission Requirement**: Node SA needs project-level snapshot permissions in the **client project**

### Required Permissions

Create a custom IAM role with only:
- `compute.snapshots.get` - Read snapshot metadata
- `compute.snapshots.list` - List snapshots for validation

**Why custom role?**
- Principle of least privilege
- Avoid granting broader roles like `roles/compute.viewer` which includes many unnecessary permissions

---

## Implementation Options

Two approaches are available, each with different trade-offs:

### Option A: principalSet Pattern (RECOMMENDED)
**Best for**: Zero-maintenance, future-proof implementation
**Grants to**: ALL service accounts in Cyngular project

- ✅ **Zero maintenance** - Automatically covers all current and future service accounts
- ✅ **No explicit SA list** - Uses GCP's principalSet pattern
- ✅ **Future-proof** - Survives cluster additions, deletions, and recreations
- ⚠️ **Broader scope** - Grants to all SAs in project (not just GKE node SAs)
- ⚠️ **Acceptable risk** - Permissions are read-only, scoped to client project

### Option B: Explicit Service Account List
**Best for**: Strict least-privilege requirements
**Grants to**: Only specified GKE node service accounts

- ✅ **Least privilege** - Only explicitly listed node service accounts
- ✅ **Granular control** - You choose exactly which SAs have access
- ⚠️ **Maintenance required** - Must update list when adding/removing clusters
- ⚠️ **Manual tracking** - Need to identify node SAs for each cluster

---

## Implementation Steps - Option A: principalSet (Recommended)

### 1. Add Variable to Client Onboarding Module

**File**: `/Users/dvirgross/Workplace/Cyngular/Devops/GCP/client-onboarding/variables.tf`

Add the Cyngular project number variable:

```hcl
variable "cyngular_project_number" {
  description = "Cyngular GCP project number (numeric ID) containing GKE clusters"
  type        = string

  # Example: "248189932415"
  # Find with: gcloud projects describe cyngular-dev --format="value(projectNumber)"
}
```

**How to get your project number:**

```bash
# For dev environment
gcloud projects describe cyngular-dev --format="value(projectNumber)"
# Output: 248189932415

# For staging environment
gcloud projects describe cyngular-stg --format="value(projectNumber)"

# For production environment
gcloud projects describe cyngular-prod --format="value(projectNumber)"
```

### 2. Update Locals Configuration

**File**: `/Users/dvirgross/Workplace/Cyngular/Devops/GCP/client-onboarding/locals.tf`

Add GKE CSI Driver configuration using principalSet:

```hcl
locals {
  # Existing locals...

  # GKE CSI Driver configuration (using principalSet)
  gke_csi_snapshot = {
    enabled = true  # Set to false to disable this feature

    # Use principalSet to grant to ALL service accounts in Cyngular project
    # This automatically includes:
    # - Default Compute Engine SAs: <PROJECT_NUMBER>-compute@developer.gserviceaccount.com
    # - Custom node service accounts
    # - Any future service accounts created
    use_principal_set = true

    # PrincipalSet format grants to all service accounts in the specified project
    principal_set = "principalSet://cloudresourcemanager.googleapis.com/projects/${var.cyngular_project_number}/type/ServiceAccount"

    custom_role = {
      role_id     = "gkeCsiSnapshotReader"
      title       = "GKE CSI Snapshot Reader"
      description = "Minimal permissions for GKE CSI driver to read snapshots for cross-project VolumeSnapshotContent"
      permissions = [
        "compute.snapshots.get",
        "compute.snapshots.list",
      ]
    }
  }
}
```

### 3. Create Custom IAM Role with principalSet Grant

**File**: `/Users/dvirgross/Workplace/Cyngular/Devops/GCP/client-onboarding/iam.tf`

Add the following resources:

```hcl
# Custom role for GKE CSI driver with minimal snapshot read permissions
resource "google_project_iam_custom_role" "gke_csi_snapshot_reader" {
  count       = local.gke_csi_snapshot.enabled ? 1 : 0
  project     = var.project_id
  role_id     = local.gke_csi_snapshot.custom_role.role_id
  title       = local.gke_csi_snapshot.custom_role.title
  description = local.gke_csi_snapshot.custom_role.description

  permissions = local.gke_csi_snapshot.custom_role.permissions
}

# Grant snapshot read permissions using principalSet
# This grants to ALL service accounts in the Cyngular project
resource "google_project_iam_member" "gke_csi_snapshot_principal_set" {
  count   = local.gke_csi_snapshot.enabled && local.gke_csi_snapshot.use_principal_set ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.gke_csi_snapshot_reader[0].id

  # principalSet pattern: grants to ALL service accounts in Cyngular project
  member  = local.gke_csi_snapshot.principal_set
}
```

### 4. Update Terragrunt Configuration

**File**: `/Users/dvirgross/Workplace/Cyngular/Devops/infra/State/Environments/dev/GCP/Clients/*/terragrunt.hcl`

Add the Cyngular project number to your inputs:

```hcl
inputs = {
  # ... existing inputs ...

  # Cyngular project number for GKE snapshot access
  cyngular_project_number = "248189932415"  # cyngular-dev project number
}
```

---

## Implementation Steps - Option B: Explicit Service Account List

### 1. Update Locals Configuration

**File**: `/Users/dvirgross/Workplace/Cyngular/Devops/GCP/client-onboarding/locals.tf`

Add GKE node service account configuration with explicit list:

```hcl
locals {
  # Existing locals...

  # GKE CSI Driver configuration (using explicit SA list)
  gke_csi_snapshot = {
    enabled = true  # Set to false to disable this feature

    # Explicit list of service accounts
    use_principal_set = false

    # List of GKE node service accounts from Cyngular clusters
    # These service accounts run the CSI driver and need snapshot read access
    node_service_accounts = [
      # Default Compute Engine service account (used by most node pools)
      "248189932415-compute@developer.gserviceaccount.com",

      # Custom node service accounts (if using custom SAs for specific node pools)
      "tf-gke-dev-gke-us-east-msra@cyngular-dev.iam.gserviceaccount.com",
      # Add additional custom node SAs here as needed
    ]

    custom_role = {
      role_id     = "gkeCsiSnapshotReader"
      title       = "GKE CSI Snapshot Reader"
      description = "Minimal permissions for GKE CSI driver to read snapshots for cross-project VolumeSnapshotContent"
      permissions = [
        "compute.snapshots.get",
        "compute.snapshots.list",
      ]
    }
  }
}
```

**How to find your node service accounts:**

```bash
# List all node pools in your GKE cluster
gcloud container node-pools list --cluster=<cluster-name> --region=<region> --project=cyngular-dev

# Get service account for a specific node pool
gcloud container node-pools describe <node-pool-name> \
  --cluster=<cluster-name> \
  --region=<region> \
  --project=cyngular-dev \
  --format="value(config.serviceAccount)"

# If output is "default", the node pool uses the default Compute Engine SA:
# <PROJECT_NUMBER>-compute@developer.gserviceaccount.com

# Get your project number
gcloud projects describe cyngular-dev --format="value(projectNumber)"
# Result: 248189932415
```

### 2. Create Custom IAM Role with Explicit Grant

**File**: `/Users/dvirgross/Workplace/Cyngular/Devops/GCP/client-onboarding/iam.tf`

Add the following resources:

```hcl
# Custom role for GKE CSI driver with minimal snapshot read permissions
resource "google_project_iam_custom_role" "gke_csi_snapshot_reader" {
  count       = local.gke_csi_snapshot.enabled ? 1 : 0
  project     = var.project_id
  role_id     = local.gke_csi_snapshot.custom_role.role_id
  title       = local.gke_csi_snapshot.custom_role.title
  description = local.gke_csi_snapshot.custom_role.description

  permissions = local.gke_csi_snapshot.custom_role.permissions
}

# Grant snapshot read permissions to specific service accounts
resource "google_project_iam_member" "gke_node_sa_snapshot_reader" {
  for_each = local.gke_csi_snapshot.enabled && !local.gke_csi_snapshot.use_principal_set ? toset(local.gke_csi_snapshot.node_service_accounts) : []

  project = var.project_id
  role    = google_project_iam_custom_role.gke_csi_snapshot_reader[0].id
  member  = "serviceAccount:${each.value}"
}
```

### 3. Environment-Specific Configuration (Optional)

If you need different node SAs for dev/staging/prod environments, you can use conditional logic in `locals.tf`:

```hcl
locals {
  # Environment detection (if not already available)
  environment = lookup({
    "cyngular-dev"  = "dev"
    "cyngular-stg"  = "stg"
    "cyngular-prod" = "prod"
  }, var.cyngular_project_id, "dev")

  # Environment-specific node service accounts
  gke_node_sas_by_env = {
    dev = [
      "248189932415-compute@developer.gserviceaccount.com",
      "tf-gke-dev-gke-us-east-msra@cyngular-dev.iam.gserviceaccount.com",
    ]
    stg = [
      "123456789012-compute@developer.gserviceaccount.com",
      "tf-gke-stg-gke-us-east-msra@cyngular-stg.iam.gserviceaccount.com",
    ]
    prod = [
      "987654321098-compute@developer.gserviceaccount.com",
      "tf-gke-prod-gke-us-east-msra@cyngular-prod.iam.gserviceaccount.com",
    ]
  }

  gke_csi_snapshot = {
    enabled               = true
    node_service_accounts = local.gke_node_sas_by_env[local.environment]

    custom_role = {
      role_id     = "gkeCsiSnapshotReader"
      title       = "GKE CSI Snapshot Reader"
      description = "Minimal permissions for GKE CSI driver to read snapshots for cross-project VolumeSnapshotContent"
      permissions = [
        "compute.snapshots.get",
        "compute.snapshots.list",
      ]
    }
  }
}
```

---

## Validation

After deployment, verify permissions:

```bash
# 1. Check custom role exists
gcloud iam roles describe gkeCsiSnapshotReader --project=<client-project-id>

# 2. Check IAM bindings for all node service accounts
gcloud projects get-iam-policy <client-project-id> \
  --flatten="bindings[].members" \
  --filter="bindings.role:projects/<client-project-id>/roles/gkeCsiSnapshotReader"

# Expected output should show all configured node service accounts:
# - serviceAccount:248189932415-compute@developer.gserviceaccount.com
# - serviceAccount:tf-gke-dev-gke-us-east-msra@cyngular-dev.iam.gserviceaccount.com

# 3. Test snapshot access from GKE cluster
kubectl apply -f <volumesnapshotcontent.yaml>
kubectl describe volumesnapshotcontent <vsc-name>
# Should show status.readyToUse: true (no 403 errors)
```

---

## Deployment Order

1. **Update locals.tf** with your GKE node service accounts
2. **Update iam.tf** with the custom role and IAM member resources
3. **Deploy to one test client** first
4. **Verify VolumeSnapshotContent creation** succeeds
5. **Roll out to all clients** via Terragrunt run-all

```bash
# Test on one client first
cd State/Environments/dev/GCP/Clients/<test-client>
terragrunt plan  # Review changes
terragrunt apply

# Verify in GKE cluster
kubectl get volumesnapshotcontent
kubectl describe volumesnapshotcontent <vsc-name>

# Roll out to all clients
cd State/Environments/dev/GCP/Clients
terragrunt run-all plan   # Review all changes
terragrunt run-all apply  # Apply to all clients
```

---

## Security Considerations

### Security Profile
- **Scope**: Only specific GKE node service accounts from Cyngular clusters
- **Permissions**: Read-only (`snapshots.get`, `snapshots.list`)
- **Impact**: Minimal - snapshots are read-only metadata, no data access
- **Risk**: Low - only authenticated node SAs from known clusters

### Security Benefits
- **Least Privilege**: Only necessary permissions granted to specific service accounts
- **No Data Access**: Snapshot permissions only grant access to metadata, not disk data
- **No Write Operations**: Cannot create, delete, or modify snapshots
- **Project-Scoped**: Permissions only apply within the client project
- **Explicit Grant**: Each service account explicitly listed in configuration

### Comparison to Alternatives

| Approach | Scope | Maintenance | Security | Flexibility |
|----------|-------|-------------|----------|-------------|
| **Option 3 (This Plan)** | Specific node SAs | Low (add new clusters to list) | ✅ High | ✅ High |
| ~~Option 1 (All SAs)~~ | All SAs in Cyngular project | Zero | ⚠️ Medium | ✅ High |
| ~~Option 2 (container-engine-robot)~~ | Wrong SA | N/A | ❌ Won't work | ❌ Won't work |

---

## Maintenance

### Adding a New GKE Cluster

When creating a new GKE cluster in the Cyngular project:

1. Identify the node service account:
   ```bash
   gcloud container node-pools describe <node-pool> \
     --cluster=<cluster-name> \
     --region=<region> \
     --format="value(config.serviceAccount)"
   ```

2. Add the service account to `locals.tf`:
   ```hcl
   node_service_accounts = [
     # Existing SAs...
     "new-node-sa@cyngular-dev.iam.gserviceaccount.com",  # New cluster
   ]
   ```

3. Run Terragrunt apply on all clients:
   ```bash
   cd State/Environments/dev/GCP/Clients
   terragrunt run-all apply
   ```

### Removing a Decommissioned Cluster

1. Remove the service account from `locals.tf`
2. Run Terragrunt apply to revoke permissions

---

## Troubleshooting

### Error: 403 Forbidden when creating VolumeSnapshotContent

**Symptom**: CSI driver logs show `compute.snapshots.get permission denied`

**Solution**:
1. Verify node service account identity:
   ```bash
   kubectl get nodes -o jsonpath='{.items[0].spec.providerID}'
   # Extract instance name and get its service account
   gcloud compute instances describe <instance-name> \
     --zone=<zone> \
     --format="value(serviceAccounts[0].email)"
   ```

2. Verify the SA is in your `locals.tf` configuration
3. Verify IAM binding exists in client project

### Custom Role Not Found

**Symptom**: Terraform error about custom role not existing

**Solution**: Ensure `depends_on` is set correctly in `iam.tf` or run `terraform apply` twice

### Service Account Format Issues

**Symptom**: IAM binding fails with invalid member format

**Solution**: Ensure service account emails follow one of these formats:
- Default Compute Engine SA: `<PROJECT_NUMBER>-compute@developer.gserviceaccount.com`
- Custom SA: `<SA_NAME>@<PROJECT_ID>.iam.gserviceaccount.com`

---

## Alternative Considered (Rejected)

**Snapshot Copy to Cyngular Project**: Copy snapshots from client project to Cyngular project after creation
- **Pros**: No client-side permissions needed
- **Cons**:
  - Additional storage costs (duplicate snapshots)
  - Increased complexity in OS service
  - Longer processing time (copy operation)
  - More API calls and potential quota issues
- **Decision**: Rejected in favor of minimal IAM permissions

**PrincipalSet for All Service Accounts**: Grant to all SAs in Cyngular project
- **Pros**: Zero maintenance, completely future-proof
- **Cons**:
  - Broader scope than necessary
  - Violates least-privilege principle
  - All SAs get access, not just GKE nodes
- **Decision**: Rejected in favor of explicit service account list
