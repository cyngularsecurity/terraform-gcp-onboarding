# Notes

## if project deleted and is in soft delete state -

### ERROR -

```bash
│ Error: error creating project cyngular-<client_name> (cyngular <client_name>): googleapi: Error 409: Requested entity already exists, alreadyExists. If you received a 403 error, make sure you have the `roles/resourcemanager.projectCreator` permission
```

### SOLUTION -

```bash
# undelete project
gcloud projects undelete cyngular-<client_name>

# terraform import
# if using module call
terraform import --var-file tfvars/<client_name>.tfvars \
    module.cyngular_gcp_onboarding.google_project.cyngular_project cyngular-<client_name>

# if using local plain tf
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
# re-run (permissions must have sunk in after 30 seconds)
terraform apply
```

## re-trigger cloud run function

```bash
# taint
terraform taint module.cyngular_func.terraform_data.call_cloud_function

# re-apply
terraform apply
```

## re-apply issues

### re-creating iam bindings of service account

### ERROR -

│ Error: Error applying IAM policy for Bigquery Dataset <project name>:<dataset name>: Error creating DatasetAccess: googleapi: Error 400: IAM setPolicy failed for Dataset <project name>:<dataset name>: The member deleted:serviceaccount:cyngular-cf-sa@<project name>.iam.gserviceaccount.com?uid=xxxxxxxxxxxxxxxxxxx is of an unknown type. Please set a valid type prefix for the member., invalid

### SOLUTION -

```bash
# clean up IAM policy list on the bq dataset
bash ./scripts/clean_bq_iam.sh <project name> <dataset name>
```
