# Notes

## if project deleted and is in soft delete state -

### ERROR -

```bash
│ Error: error creating project cyngular-se7enup (cyngular se7enup): googleapi: Error 409: Requested entity already exists, alreadyExists. If you received a 403 error, make sure you have the `roles/resourcemanager.projectCreator` permission
```

### SOLUTION -

```bash
# undelete project
gcloud projects undelete cyngular-<client_name>

# terraform import
terraform import --var-file tfvars/<client_name>.tfvars \
    google_project.cyngular_project cyngular-<client_name>
```

## Off Boarding

erroring on terraform destroy of bigquery - since dataset contains tables (audit logs) created by the Log Sink

### ERROR -

```bash
│ Error: Error when reading or editing Dataset: googleapi: Error 400: Dataset '<project name>:<dataset name>' is still in use, resourceInUse
```

### SOLUTION -

```bash
# use gcloud cli 'bq' to force delete dataset
bq rm -r -f -d '<project name>:<dataset name>'
```

## Apply time - False Negatives

### ERROR -

```bash
│ Error: Error waiting to create function: Error waiting for Creating function: Error code 3, message: Build failed with status: FAILURE and message: Access to bucket .... denied. You must grant Storage Object Viewer permission to cyngular-cloud-build-sa@<project name>.iam.gserviceaccount.com. If you are using VPC Service Controls, you must also grant it access to your service perimeter.
```

### SOLUTION -

```bash
# rerun (permissions must have sunk in after 30 seconds)
terraform apply
```

## Retrigger cloud run function

```bash
# taint
terraform taint module.cyngular_func.terraform_data.call_cloud_function

# reapply
terraform apply
```
