# Troubleshooting Guide

## Permission Errors (403)

**Symptom**: `Error 403: The caller does not have permission`

**Solution**: Ensure you have the required organization-level roles. See [MANUAL_PERMISSION_SETUP.md](./MANUAL_PERMISSION_SETUP.md).

## Custom Role Already Exists

**Symptom**: `Custom role already exists and must be imported`

**Solution**: Import existing resources:

```bash
terraform import google_organization_iam_custom_role.cyngular_custom \
  organizations/{ORG_ID}/roles/cyngularOrgRole
```

## Project Already Exists

**Symptom**: `Project {project_id} already exists`

**Solution**: Import existing project:

```bash
terraform import google_project.cyngular_project {project_id}
```

## Cloud Function Fails to Deploy

**Symptom**: Cloud Function creation timeout or errors

**Solution**:

1. Verify Cloud Functions API is enabled
2. Check service account permissions
3. Review Cloud Build logs for build errors

## Client Name Validation Error

**Symptom**: `client_name must contain only lowercase letters and numbers`

**Solution**: Use only lowercase letters (a-z) and numbers (0-9). No hyphens, underscores, or uppercase letters.
