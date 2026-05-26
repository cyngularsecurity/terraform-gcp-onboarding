#!/bin/bash
#
# Enable the GCP APIs required for Cyngular onboarding on every active project
# under the given organization, including projects nested in folders. The script
# is idempotent: already-enabled APIs are reported and skipped.
#
# Usage:   ./enable_apis.sh <organization_id> [--dry-run]
# Output:  one line per project: "<project_id>  [<hierarchy>]  <outcome>"
#
# Required permissions:
#   Organization: resourcemanager.projects.list, resourcemanager.folders.list
#   Per project:  serviceusage.services.list, serviceusage.services.enable
#
# Per-project preconditions:
#   - Service Usage API enabled (default on new projects)
#   - Linked billing account (required for compute, container, run,
#     cloudfunctions, and sqladmin)

set -euo pipefail

APIS=(
  cloudasset.googleapis.com
  admin.googleapis.com
  apikeys.googleapis.com
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

PROJECTS=()
PATHS=()

# collect <parent_type> <parent_id> <display_path>
#   parent_type: "organization" or "folder"
collect() {
  local parent_type="$1" parent_id="$2" path="$3"

  while IFS= read -r proj; do
    [[ -n "$proj" ]] || continue
    PROJECTS+=("$proj")
    PATHS+=("$path")
  done < <(
    gcloud projects list \
      --filter="parent.id=$parent_id AND parent.type=$parent_type" \
      --format="value(projectId)" 2>/dev/null
  )

  local folder_flag
  if [[ "$parent_type" == "organization" ]]; then
    folder_flag="--organization=$parent_id"
  else
    folder_flag="--folder=$parent_id"
  fi

  while IFS=$'\t' read -r fname fdisplay; do
    [[ -n "$fname" ]] || continue
    local fid="${fname#folders/}"
    collect "folder" "$fid" "$path/$fdisplay"
  done < <(
    gcloud resource-manager folders list $folder_flag \
      --format="value(name,displayName)" 2>/dev/null
  )
}

echo "Walking hierarchy under organization $ORG_ID..."
collect "organization" "$ORG_ID" "org"

TOTAL=${#PROJECTS[@]}
if [[ $TOTAL -eq 0 ]]; then
  echo "No accessible projects found under organization $ORG_ID." >&2
  exit 0
fi

echo "Found $TOTAL project(s)."
echo

FAILED_PROJECTS=()

MAX_PROJ=0
MAX_PATH=0
for i in "${!PROJECTS[@]}"; do
  (( ${#PROJECTS[$i]} > MAX_PROJ )) && MAX_PROJ=${#PROJECTS[$i]}
  (( ${#PATHS[$i]}    > MAX_PATH )) && MAX_PATH=${#PATHS[$i]}
done

for i in "${!PROJECTS[@]}"; do
  PROJECT="${PROJECTS[$i]}"
  HPATH="${PATHS[$i]}"
  LINE_PREFIX=$(printf "%-${MAX_PROJ}s  [%-${MAX_PATH}s]" "$PROJECT" "$HPATH")

  ENABLED="$(gcloud services list --enabled \
    --project="$PROJECT" \
    --format="value(config.name)" 2>/dev/null || echo "__ERR__")"

  if [[ "$ENABLED" == "__ERR__" ]]; then
    echo "$LINE_PREFIX  SKIP: cannot list services"
    FAILED_PROJECTS+=("$PROJECT")
    continue
  fi

  TO_ENABLE=()
  for API in "${APIS[@]}"; do
    grep -qx "$API" <<<"$ENABLED" || TO_ENABLE+=("$API")
  done

  if [[ ${#TO_ENABLE[@]} -eq 0 ]]; then
    echo "$LINE_PREFIX  ok"
    continue
  fi

  TO_ENABLE_CSV="$(IFS=,; echo "${TO_ENABLE[*]}")"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "$LINE_PREFIX  would enable: $TO_ENABLE_CSV"
    continue
  fi

  ERR_OUT="$(gcloud services enable "${TO_ENABLE[@]}" --project="$PROJECT" 2>&1 >/dev/null)" || {
    REASON=$(echo "$ERR_OUT" | grep -E '^ERROR|FAILED_PRECONDITION|PERMISSION_DENIED' | head -1)
    [[ -z "$REASON" ]] && REASON="$(echo "$ERR_OUT" | head -1)"
    echo "$LINE_PREFIX  FAILED: $REASON"
    FAILED_PROJECTS+=("$PROJECT")
    continue
  }
  echo "$LINE_PREFIX  enabled: $TO_ENABLE_CSV"
done

echo
echo "Done. Processed $TOTAL project(s)."
if [[ ${#FAILED_PROJECTS[@]} -gt 0 ]]; then
  echo "Projects with failures: ${FAILED_PROJECTS[*]}" >&2
  exit 1
fi
