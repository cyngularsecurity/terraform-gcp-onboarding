#!/bin/bash
#
# clean_bq_iam.sh - Remove deleted IAM principals from BigQuery dataset access controls
#
# DESCRIPTION:
#   When users or service accounts are deleted from GCP, their IAM bindings remain
#   in BigQuery dataset access controls as "deleted:" entries. This script removes
#   those stale entries to keep dataset permissions clean.
#
# PREREQUISITES:
#   - gcloud CLI authenticated with appropriate permissions
#   - bq CLI (part of gcloud SDK)
#   - jq (JSON processor) installed
#   - BigQuery Admin or Dataset Owner permissions on the target dataset
#
# USAGE:
#   ./clean_bq_iam.sh <project_id> <dataset_id>
#
# EXAMPLES:
#   ./clean_bq_iam.sh my-gcp-project analytics_dataset
#   ./clean_bq_iam.sh prod-project-123 billing_data
#
# EXIT CODES:
#   0 - Success (cleanup performed or no cleanup needed)
#   1 - Missing required arguments
#   Non-zero - bq/jq command failure
#
set -e

PROJECT_ID=$1
DATASET_ID=$2

# Validate required arguments
if [ -z "$PROJECT_ID" ] || [ -z "$DATASET_ID" ]; then
  echo "Usage: $0 <project_id> <dataset_id>"
  exit 1
fi

# Format: project_id:dataset_id (required by bq CLI)
FULL_DATASET="${PROJECT_ID}:${DATASET_ID}"
echo "Fetching metadata for dataset ${FULL_DATASET}..."

# Export current dataset metadata including access controls
bq show --format=prettyjson "${FULL_DATASET}" > dataset.json

# Check for deleted principals in the access block
# Deleted members appear with prefix "deleted:" in userByEmail or iamMember fields
if grep -q "deleted:" dataset.json; then
  echo "Found deleted principals in dataset access controls. Cleaning up..."

  # Filter out entries where userByEmail or iamMember starts with "deleted:"
  # The jq filter:
  #   - .access |= map(...) - update the access array
  #   - select(...) - keep only entries that don't match deleted pattern
  #   - (.field // "") - use empty string if field doesn't exist (null-safe)
  jq '.access |= map(select((.userByEmail // "") | startswith("deleted:") | not) | select((.iamMember // "") | startswith("deleted:") | not))' dataset.json > clean_dataset.json

  # Apply the cleaned access controls back to the dataset
  echo "Updating dataset with cleaned access controls..."
  bq update --source clean_dataset.json "${FULL_DATASET}"

  echo "Cleanup complete."
  rm dataset.json clean_dataset.json
else
  echo "No deleted principals found."
  rm dataset.json
fi
