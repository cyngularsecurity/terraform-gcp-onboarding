#!/bin/bash
set -e

# Usage: ./clean_bq_iam.sh <project_id> <dataset_id>

PROJECT_ID=$1
DATASET_ID=$2

if [ -z "$PROJECT_ID" ] || [ -z "$DATASET_ID" ]; then
  echo "Usage: $0 <project_id> <dataset_id>"
  exit 1
fi

FULL_DATASET="${PROJECT_ID}:${DATASET_ID}"
echo "Fetching metadata for dataset ${FULL_DATASET}..."

# Fetch dataset metadata in JSON format
bq show --format=prettyjson "${FULL_DATASET}" > dataset.json

# Check for deleted members in the 'access' block
# deleted members can appear in 'userByEmail' or 'iamMember'
if grep -q "deleted:" dataset.json; then
  echo "Found deleted principals in dataset access controls. Cleaning up..."
  
  # Filter out deleted members using jq
  # We check both userByEmail and iamMember fields if they exist
  jq '.access |= map(select((.userByEmail // "") | startswith("deleted:") | not) | select((.iamMember // "") | startswith("deleted:") | not))' dataset.json > clean_dataset.json

  echo "Updating dataset with cleaned access controls..."
  bq update --source clean_dataset.json "${FULL_DATASET}"
  
  echo "Cleanup complete."
  rm dataset.json clean_dataset.json
else
  echo "No deleted principals found."
  rm dataset.json
fi
