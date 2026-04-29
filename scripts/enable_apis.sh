#!/bin/bash
#
# enable_apis.sh - Enable required GCP APIs on all projects under an organization
#
# DESCRIPTION:
#   Iterates over every project accessible to the currently logged-in gcloud
#   account within the given organization and enables the APIs required for
#   Cyngular onboarding. APIs already enabled are skipped (gcloud is idempotent,
#   but we check first to avoid unnecessary calls and produce clearer output).
#
# PREREQUISITES:
#   - gcloud CLI authenticated (`gcloud auth login`)
#   - serviceusage.services.enable permission on the target projects
#
# USAGE:
#   ./enable_apis.sh <organization_id> [--dry-run]
#
# EXAMPLES:
#   ./enable_apis.sh 123456789012
#   ./enable_apis.sh 123456789012 --dry-run

set -euo pipefail

APIS=(
  cloudasset.googleapis.com
  admin.googleapis.com
  sqladmin.googleapis.com
  iam.googleapis.com
  cloudresourcemanager.googleapis.com
  storage.googleapis.com
  compute.googleapis.com
  container.googleapis.com
  cloudfunctions.googleapis.com
  run.googleapis.com
)

usage() {
  echo "Usage: $0 <organization_id> [--dry-run]" >&2
  exit 1
}

[[ $# -lt 1 || $# -gt 2 ]] && usage
ORG_ID="$1"
DRY_RUN="false"
[[ "${2:-}" == "--dry-run" ]] && DRY_RUN="true"

ACCOUNT="$(gcloud config get-value account 2>/dev/null || true)"
if [[ -z "$ACCOUNT" ]]; then
  echo "ERROR: no active gcloud account. Run 'gcloud auth login' first." >&2
  exit 1
fi

echo "Active account : $ACCOUNT"
echo "Organization   : $ORG_ID"
echo "Dry run        : $DRY_RUN"
echo

echo "Listing projects under organization $ORG_ID..."
PROJECTS=()
while IFS= read -r line; do
  [[ -n "$line" ]] && PROJECTS+=("$line")
done < <(
  gcloud projects list \
    --filter="parent.id=$ORG_ID AND lifecycleState=ACTIVE" \
    --format="value(projectId)"
)

if [[ ${#PROJECTS[@]} -eq 0 ]]; then
  echo "No accessible active projects found under organization $ORG_ID." >&2
  exit 0
fi

echo "Found ${#PROJECTS[@]} project(s)."
echo

FAILED_PROJECTS=()

for PROJECT in "${PROJECTS[@]}"; do
  echo "==> $PROJECT"

  ENABLED="$(gcloud services list --enabled \
    --project="$PROJECT" \
    --format="value(config.name)" 2>/dev/null || echo "__ERR__")"

  if [[ "$ENABLED" == "__ERR__" ]]; then
    echo "    SKIP: cannot list services (insufficient permissions or API disabled)"
    FAILED_PROJECTS+=("$PROJECT")
    echo
    continue
  fi

  TO_ENABLE=()
  for API in "${APIS[@]}"; do
    if grep -qx "$API" <<<"$ENABLED"; then
      echo "    ok:     $API"
    else
      TO_ENABLE+=("$API")
    fi
  done

  if [[ ${#TO_ENABLE[@]} -eq 0 ]]; then
    echo "    all required APIs already enabled."
    echo
    continue
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    for API in "${TO_ENABLE[@]}"; do
      echo "    would enable: $API"
    done
  else
    echo "    enabling ${#TO_ENABLE[@]} API(s)..."
    if gcloud services enable "${TO_ENABLE[@]}" --project="$PROJECT" >/dev/null 2>&1; then
      for API in "${TO_ENABLE[@]}"; do
        echo "    enabled: $API"
      done
    else
      echo "    FAILED to enable APIs on $PROJECT"
      FAILED_PROJECTS+=("$PROJECT")
    fi
  fi
  echo
done

echo "Done."
if [[ ${#FAILED_PROJECTS[@]} -gt 0 ]]; then
  echo "Projects with failures: ${FAILED_PROJECTS[*]}" >&2
  exit 1
fi
