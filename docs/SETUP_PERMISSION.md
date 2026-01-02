# GCP Organization Permissions Setup Guide

This guide explains the permission issues you may encounter when deploying the Cyngular onboarding Terraform module and how to resolve them.

## Summary

Even with "Owner" role at the organization level, Terraform may fail with 403 permission errors when:

1. Creating organization-level IAM bindings (`google_organization_iam_member`)
2. Creating organization-level custom roles
3. Creating projects under the organization

This is because **organization-level Owner role does NOT automatically grant write access to organization IAM policies**.

---

## Minimum Required Organization Permissions

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

1. Navigate to: <https://console.cloud.google.com/iam-admin/iam?organizationId=795614755097>
2. Find user: `dvirg@cyngularsecurity.com`
3. Click **Edit principal** (pencil icon)
4. Click **Add another role** (3 times)
5. Add these roles:
   - **Organization Administrator**
   - **Organization Role Administrator**
   - **Project Creator**
6. Click **Save**

---

## Verification

```bash
gcloud organizations get-iam-policy ${ORG_ID} \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:${USER_EMAIL}" \
  --format="table(bindings.role)"
```

expected output:

- `roles/resourcemanager.organizationAdmin`
- `roles/iam.organizationRoleAdmin`
- `roles/resourcemanager.projectCreator`
