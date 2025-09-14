
## Quick start

1. Install the prerequisites (Terraform and gcloud CLI).
2. Authenticate with Google Cloud.
3. Initialize Terraform, review the plan, and apply.



Install links 

- Terraform: https://developer.hashicorp.com/terraform/install
- gcloud CLI: https://cloud.google.com/sdk/docs/install

## Recommended setup

1. Make sure `terraform` and `gcloud` are available in your PATH:

```bash
terraform -v
gcloud version
```

2. Ensure you have access to the backend bucket(If using a remote state) and appropriate IAM roles.
- Project Creator
- 

## Authenticate with Google Cloud
Auth using Application Default Credentials and to the gcloud CLI

```bash
gcloud auth login       # (Optional)
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

- gcloud auth login is used to authenticate gcloud CLI command 
- gcloud auth application-default login is used for Client libraries and tools(Terraform etc)


## Variables

- `terraform.tfvars` in this directory provides the default input values.

Example:

```hcl
organization_id = 123456789
billing_account = "AAAAA-BBBBB-CCCCC"

client_name = "CLIENT_NAME"

organization_audit_logs = {
  audit_log_configuration = {
    enable_admin_read = true/false
    enable_data_read  = true/false
    enable_data_write = true/false
  }
  enable_bigquery_export = true/false
  bq_location = "REGION OR MULTIRGION" # By default us-east4
  existing_bq_dataset = { # Needs to be set if enable_bigquery_export is false
    dataset_id = DATASET_NAME
    project_id = DATASET_PROJECT
  }
}

```

## Terraform workflow
```bash
cd client/

# Initialize providers and backend
terraform init

# Inspect what Terraform will change
terraform plan -var-file=terraform.tfvars

# Apply changes (review the plan carefully first)
terraform apply -var-file=terraform.tfvars
```

## Backend (remote state)

If you'd like to use a remote state, uncommend the backend.tf block and fill in the bucket name and the path to the terraform.tfvars file that will be stored inside


