# GCP Organization Permissions Setup Guide

This guide explains the permission issues you may encounter when deploying the Cyngular onboarding Terraform module and how to resolve them.

## Problem Summary

Even with "Owner" role at the organization level, Terraform may fail with 403 permission errors when:
1. Creating organization-level IAM bindings (`google_organization_iam_member`)
2. Creating organization-level custom roles (if not already created)
3. Creating projects under the organization

This is because **organization-level Owner role does NOT automatically grant write access to organization IAM policies**.

---

# Solution: Required Organization Permissions

## Minimum Required Roles

The user running Terraform needs these organization-level roles:

1. **Organization Administrator** (`roles/resourcemanager.organizationAdmin`)
   - Required for: Creating organization IAM bindings
   - Grants: `resourcemanager.organizations.setIamPolicy`

2. **Organization Role Administrator** (`roles/iam.organizationRoleAdmin`)
   - Required for: Creating/updating custom roles at org level
   - Grants: `iam.roles.create`, `iam.roles.update`, `iam.roles.delete`

3. **Project Creator** (`roles/resourcemanager.projectCreator`)
   - Required for: Creating new projects under the organization
   - Grants: `resourcemanager.projects.create`

---

# Quick Fix: Grant Missing Permissions

## Option 1: Using gcloud CLI (Recommended)

Have an organization admin run these commands:

```bash
# Set variables
ORG_ID="795614755097"
USER_EMAIL="dvirg@cyngularsecurity.com"

# Grant Organization Administrator role
gcloud organizations add-iam-policy-binding ${ORG_ID} \
  --member="user:${USER_EMAIL}" \
  --role="roles/resourcemanager.organizationAdmin" \
  --condition=None

# Grant Organization Role Administrator
gcloud organizations add-iam-policy-binding ${ORG_ID} \
  --member="user:${USER_EMAIL}" \
  --role="roles/iam.organizationRoleAdmin" \
  --condition=None

# Grant Project Creator
gcloud organizations add-iam-policy-binding ${ORG_ID} \
  --member="user:${USER_EMAIL}" \
  --role="roles/resourcemanager.projectCreator" \
  --condition=None
```

## Option 2: Using GCP Console

1. Navigate to: https://console.cloud.google.com/iam-admin/iam?organizationId=795614755097
2. Find user: `dvirg@cyngularsecurity.com`
3. Click **Edit principal** (pencil icon)
4. Click **Add another role** (3 times)
5. Add these roles:
   - **Organization Administrator**
   - **Organization Role Administrator**
   - **Project Creator**
6. Click **Save**

---

# Terraform Import for Existing Resources

Your errors show that some resources already exist and need to be imported into Terraform state:

## 1. Import Existing Custom Role

```bash
terraform import google_organization_iam_custom_role.cyngular_custom \
  organizations/795614755097/roles/cyngularOrgRole
```

## 2. Import Existing Project (if it exists)

```bash
# Check if project exists
gcloud projects describe suzuki-cyngular 2>/dev/null

# If it exists, import it
terraform import google_project.cyngular_project suzuki-cyngular
```

## 3. Import Existing IAM Bindings (if they exist)

You'll need to import any existing organization IAM bindings. First, check what exists:

```bash
# Check for existing cloud function SA bindings
gcloud organizations get-iam-policy 795614755097 \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:cyngular-cf-sa@suzuki-cyngular.iam.gserviceaccount.com" \
  --format="table(bindings.role,bindings.members)"
```

If the service account already has org-level roles, import them:

```bash
# Import format: <org_id> <role> <member>
terraform import 'google_organization_iam_member.cloud_function_roles["roles/viewer"]' \
  "795614755097 roles/viewer serviceAccount:cyngular-cf-sa@suzuki-cyngular.iam.gserviceaccount.com"

terraform import 'google_organization_iam_member.cloud_function_roles["roles/browser"]' \
  "795614755097 roles/browser serviceAccount:cyngular-cf-sa@suzuki-cyngular.iam.gserviceaccount.com"
```

---

# Complete Deployment Workflow

After permissions are granted and existing resources imported:

```bash
# 1. Initialize Terraform (if not done)
cd /Users/dvirgross/Workplace/Cyngular/Devops/GCP/client-onboarding
terraform init

# 2. Import existing resources (run all import commands above)

# 3. Plan deployment
terraform plan --var-file tfvars/suzuki.tfvars

# 4. Apply (after reviewing plan)
terraform apply --var-file tfvars/suzuki.tfvars
```

---

# Understanding the Errors

## Error 1: IAM Policy Retrieval (403)
```
Error retrieving IAM policy for organization "795614755097":
googleapi: Error 403: The caller does not have permission
```

**Cause**: Missing `roles/resourcemanager.organizationAdmin`
**Fix**: Grant Organization Administrator role

## Error 2: Custom Role Already Exists
```
Custom project role organizations/795614755097/roles/cyngularOrgRole
already exists and must be imported
```

**Cause**: Role created in previous run, not in Terraform state
**Fix**: Run terraform import command (see above)

## Error 3: Project Creation (403)
```
Permission 'resourcemanager.projects.create' denied
```

**Cause**: Missing `roles/resourcemanager.projectCreator`
**Fix**: Grant Project Creator role

---

# Verification

After granting permissions, verify them:

```bash
# Check your permissions
gcloud organizations get-iam-policy 795614755097 \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:dvirg@cyngularsecurity.com" \
  --format="table(bindings.role)"
```

You should see:
- `roles/resourcemanager.organizationAdmin`
- `roles/iam.organizationRoleAdmin`
- `roles/resourcemanager.projectCreator`
- `roles/owner` (your existing role)

---

# Security Best Practices

## Principle of Least Privilege

For production, consider creating a custom role with only these permissions:

```yaml
name: "TerraformDeployerOrgRole"
permissions:
  # Organization IAM
  - resourcemanager.organizations.getIamPolicy
  - resourcemanager.organizations.setIamPolicy

  # Custom Roles
  - iam.roles.create
  - iam.roles.update
  - iam.roles.get
  - iam.roles.list

  # Project Creation
  - resourcemanager.projects.create
  - resourcemanager.projects.get

  # Audit Logs
  - logging.sinks.create
  - logging.sinks.update
  - logging.sinks.get
```

## Alternative: Service Account Impersonation

Instead of granting these powerful roles to user accounts:

1. Create a dedicated service account with required permissions
2. Use service account impersonation for Terraform operations

```bash
# Create dedicated SA (as org admin)
gcloud iam service-accounts create cyngular-terraform-deployer \
  --display-name="Cyngular Terraform Deployer" \
  --project=YOUR_ADMIN_PROJECT

# Grant it the required roles
SA_EMAIL="cyngular-terraform-deployer@YOUR_ADMIN_PROJECT.iam.gserviceaccount.com"

gcloud organizations add-iam-policy-binding 795614755097 \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/resourcemanager.organizationAdmin"

gcloud organizations add-iam-policy-binding 795614755097 \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.organizationRoleAdmin"

gcloud organizations add-iam-policy-binding 795614755097 \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/resourcemanager.projectCreator"

# Grant yourself impersonation rights
gcloud iam service-accounts add-iam-policy-binding ${SA_EMAIL} \
  --member="user:dvirg@cyngularsecurity.com" \
  --role="roles/iam.serviceAccountTokenCreator"

# Use impersonation in Terraform
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=${SA_EMAIL}
terraform plan --var-file tfvars/suzuki.tfvars
```

---

# GKE CSI Snapshot Permissions (Original Content Below)

The following section covers the separate GKE CSI snapshot permissions setup:

## Step 1: Get Cyngular Project Number

**Project**: `cyngular-dev`

1. Open GCP Console: https://console.cloud.google.com
2. Select project: **cyngular-dev**
3. Navigate to: **IAM & Admin** → **Settings**
4. Copy the **Project number** (e.g., `248189932415`)

**Alternative - Using gcloud CLI:**
```bash
gcloud projects describe cyngular-dev --format="value(projectNumber)"
```

Expected output: `248189932415`

---

## Step 2: Create Custom IAM Role (Client Project)

**Project**: Switch to your **CLIENT PROJECT** (e.g., `zippy-catwalk-468816-n0`)

1. Navigate to: **IAM & Admin** → **Roles**
2. Click **+ CREATE ROLE**
3. Fill in the form:

   **Basic Information:**
   - **Title**: `GKE CSI Snapshot Reader`
   - **Description**: `Minimal permissions for GKE CSI driver to read snapshots for cross-project VolumeSnapshotContent`
   - **ID**: `gkeCsiSnapshotReader`
   - **Role launch stage**: General Availability

4. Click **+ ADD PERMISSIONS**

5. Add these two permissions:
   - Filter for: `compute.snapshots.get`
     - ✅ Check the box
   - Filter for: `compute.snapshots.list`
     - ✅ Check the box

6. Click **ADD** (to add permissions)

7. Click **CREATE** (to create the role)

✅ Custom role created: `projects/<CLIENT_PROJECT_ID>/roles/gkeCsiSnapshotReader`

---

## Step 3: Grant Role Using PrincipalSet (Recommended)

**Still in CLIENT PROJECT**

1. Navigate to: **IAM & Admin** → **IAM**

2. Click **+ GRANT ACCESS**

3. In the **Add principals** section:

   **New principals:** (paste this exactly, replacing PROJECT_NUMBER)
   ```
   principalSet://cloudresourcemanager.googleapis.com/projects/248189932415/type/ServiceAccount
   ```

   ⚠️ **Replace `248189932415`** with your actual Cyngular project number from Step 1

4. In the **Assign roles** section:
   - Click **Select a role**
   - Search for: `GKE CSI Snapshot Reader`
   - Select: **GKE CSI Snapshot Reader** (under "Custom")

5. Click **SAVE**

### What This Does

The `principalSet` pattern grants the role to **ALL service accounts** in the Cyngular project (`cyngular-dev`), including:
- Default Compute Engine SA: `248189932415-compute@developer.gserviceaccount.com`
- Custom node service accounts (e.g., `tf-gke-dev-gke-us-east-msra@cyngular-dev.iam.gserviceaccount.com`)
- Any future service accounts created

---

## Alternative: Step 3B - Grant to Specific Service Accounts (Optional)

If you prefer to grant only to specific GKE node service accounts instead of using principalSet:

### Find Your GKE Node Service Accounts

**Project**: Switch to **cyngular-dev**

```bash
# List all GKE clusters
gcloud container clusters list --project=cyngular-dev

# For each cluster, get node pool service accounts
gcloud container node-pools list \
  --cluster=<CLUSTER_NAME> \
  --region=<REGION> \
  --project=cyngular-dev

# Get service account for specific node pool
gcloud container node-pools describe <NODE_POOL_NAME> \
  --cluster=<CLUSTER_NAME> \
  --region=<REGION> \
  --project=cyngular-dev \
  --format="value(config.serviceAccount)"
```

If output is `default`, the node pool uses:
```
248189932415-compute@developer.gserviceaccount.com
```

### Grant to Specific Service Accounts

**Project**: Switch back to **CLIENT PROJECT**

1. Navigate to: **IAM & Admin** → **IAM**
2. Click **+ GRANT ACCESS**
3. **New principals**: Enter the service account email (e.g., `248189932415-compute@developer.gserviceaccount.com`)
4. **Assign roles**: Select **GKE CSI Snapshot Reader**
5. Click **SAVE**
6. Repeat for each additional service account

---

## Step 4: Verify Permissions

### Verify Custom Role Exists

**Project**: CLIENT PROJECT

1. Navigate to: **IAM & Admin** → **Roles**
2. Search for: `GKE CSI Snapshot Reader`
3. Click on the role to view details
4. Verify permissions:
   - ✅ `compute.snapshots.get`
   - ✅ `compute.snapshots.list`

### Verify IAM Bindings

**Project**: CLIENT PROJECT

1. Navigate to: **IAM & Admin** → **IAM**
2. Use filter: `GKE CSI Snapshot Reader`
3. You should see:
   - **Option A (PrincipalSet)**: Entry showing `principalSet://...`
   - **Option B (Explicit)**: Multiple entries for each service account

**Using gcloud CLI:**
```bash
# Check IAM policy for the custom role
gcloud projects get-iam-policy <CLIENT_PROJECT_ID> \
  --flatten="bindings[].members" \
  --filter="bindings.role:projects/<CLIENT_PROJECT_ID>/roles/gkeCsiSnapshotReader" \
  --format="table(bindings.role,bindings.members)"
```

Expected output (Option A):
```
ROLE                                                              MEMBERS
projects/zippy-catwalk-468816-n0/roles/gkeCsiSnapshotReader     principalSet://cloudresourcemanager.googleapis.com/projects/248189932415/type/ServiceAccount
```

Expected output (Option B):
```
ROLE                                                              MEMBERS
projects/zippy-catwalk-468816-n0/roles/gkeCsiSnapshotReader     serviceAccount:248189932415-compute@developer.gserviceaccount.com
projects/zippy-catwalk-468816-n0/roles/gkeCsiSnapshotReader     serviceAccount:tf-gke-dev-gke-us-east-msra@cyngular-dev.iam.gserviceaccount.com
```

---

## Step 5: Test VolumeSnapshotContent Creation

**Context**: Switch to your Cyngular GKE cluster

1. Create a test VolumeSnapshotContent YAML:

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotContent
metadata:
  name: test-cross-project-vsc
spec:
  deletionPolicy: Retain
  driver: pd.csi.storage.gke.io
  source:
    snapshotHandle: projects/zippy-catwalk-468816-n0/global/snapshots/snap-test-snapshot
  volumeSnapshotRef:
    name: test-snapshot
    namespace: default
```

2. Apply the manifest:
```bash
kubectl apply -f test-vsc.yaml
```

3. Check the status:
```bash
kubectl describe volumesnapshotcontent test-cross-project-vsc
```

**Success indicators:**
- ✅ Status shows `readyToUse: true`
- ✅ No 403 errors in events
- ✅ CSI driver successfully validated snapshot

**If you see errors:**
```bash
# Check CSI driver logs
kubectl logs -n kube-system -l app=gcp-compute-persistent-disk-csi-driver --tail=100
```

---

## Quick Reference - Project Numbers

| Environment | Project ID      | Project Number  |
|-------------|-----------------|-----------------|
| Dev         | cyngular-dev    | 248189932415    |
| Staging     | cyngular-stg    | (get via gcloud)|
| Production  | cyngular-prod   | (get via gcloud)|

**Get any project number:**
```bash
gcloud projects describe <PROJECT_ID> --format="value(projectNumber)"
```

---

## Troubleshooting

### Issue: principalSet format not accepted

**Symptom**: Error when adding principalSet in IAM console

**Solution**: Ensure you're using the exact format:
```
principalSet://cloudresourcemanager.googleapis.com/projects/PROJECT_NUMBER/type/ServiceAccount
```
- ⚠️ Use PROJECT_NUMBER (numeric), NOT project ID (string)
- ⚠️ No trailing slashes
- ⚠️ Case-sensitive

### Issue: Still getting 403 errors after granting permissions

**Possible causes:**
1. Used project ID instead of project NUMBER in principalSet
2. Wrong client project (check snapshot project vs where you granted permissions)
3. IAM propagation delay (wait 1-2 minutes)
4. Wrong node service account (verify what your GKE nodes actually use)

**Debug steps:**
```bash
# 1. Verify which SA is being used by CSI driver
kubectl get pods -n kube-system -l app=gcp-compute-persistent-disk-csi-driver -o yaml | grep serviceAccountName

# 2. Get the node's service account
kubectl get nodes -o jsonpath='{.items[0].spec.providerID}'
# Extract instance name and check its SA

# 3. Check IAM policy includes that SA
gcloud projects get-iam-policy <CLIENT_PROJECT_ID> \
  --flatten="bindings[].members" \
  --filter="bindings.role:projects/<CLIENT_PROJECT_ID>/roles/gkeCsiSnapshotReader"
```

### Issue: Custom role not appearing in dropdown

**Solution**: Clear browser cache or use incognito mode. Newly created custom roles can take a few seconds to appear.

---

## Security Notes

✅ **Read-only permissions**: Only `get` and `list`, no write/delete
✅ **Scoped to client project**: Permissions only work in the specific client project
✅ **No data access**: Snapshot metadata only, not disk contents
✅ **Automatic coverage**: PrincipalSet covers all current and future SAs

---

## Next Steps

After successful testing:
1. Document the client project ID and permissions granted
2. Consider automating this via Terraform (see main plan document)
3. Roll out to other client projects as needed
4. Add monitoring for 403 errors in CSI driver logs