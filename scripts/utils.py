"""
GCP utilities for querying log sinks, BigQuery datasets, and organizations.

This module provides helper functions for gathering information needed
to populate Terraform variables when working with existing GCP resources.
"""

from typing import Any

from google.cloud import bigquery, resourcemanager_v3
from google.cloud.logging_v2.services.config_service_v2 import ConfigServiceV2Client
from google.cloud.logging_v2.types import ListSinksRequest


class GCPResourceDiscovery:
    """Helper class for discovering GCP resources."""

    def __init__(self) -> None:
        """Initialize GCP clients."""
        self.logging_client = ConfigServiceV2Client()
        self.bq_client = bigquery.Client()
        self.org_client = resourcemanager_v3.OrganizationsClient()

    def list_organizations(self) -> list[dict[str, Any]]:
        """
        List all GCP organizations accessible to the current credentials.

        Returns:
            List of organization dictionaries with id, display_name, and state
        """
        orgs = []
        try:
            request = resourcemanager_v3.SearchOrganizationsRequest()
            page_result = self.org_client.search_organizations(request=request)

            for org in page_result:
                orgs.append(
                    {
                        "id": org.name.split("/")[-1],
                        "display_name": org.display_name,
                        "state": org.state.name,
                        "full_name": org.name,
                    }
                )
        except Exception as e:
            print(f"Error listing organizations: {e}")
            print("Make sure you have proper permissions to list organizations")

        return orgs

    def get_org_log_sinks(self, org_id: str) -> list[dict[str, Any]]:
        """
        Get all log sinks configured at the organization level.

        Args:
            org_id: Organization ID (numeric)

        Returns:
            List of log sink dictionaries with details
        """
        sinks = []
        try:
            parent = f"organizations/{org_id}"
            request = ListSinksRequest(parent=parent)
            page_result = self.logging_client.list_sinks(request=request)

            for sink in page_result:
                sink_info = {
                    "name": sink.name,
                    "destination": sink.destination,
                    "filter": sink.filter,
                    "include_children": sink.include_children,
                    "writer_identity": sink.writer_identity,
                }

                # Parse destination for BigQuery info
                if "bigquery.googleapis.com" in sink.destination:
                    parts = sink.destination.replace(
                        "bigquery.googleapis.com/", ""
                    ).split("/")
                    if len(parts) >= 4:  # projects/PROJECT_ID/datasets/DATASET_ID
                        sink_info["bq_project_id"] = parts[1]
                        sink_info["bq_dataset_id"] = parts[3]

                sinks.append(sink_info)

        except Exception as e:
            print(f"Error listing log sinks for org {org_id}: {e}")
            print("Make sure you have proper permissions (roles/logging.viewer)")

        return sinks

    def get_bq_dataset_info(
        self, project_id: str, dataset_id: str
    ) -> dict[str, Any] | None:
        """
        Get detailed information about a BigQuery dataset.

        Args:
            project_id: GCP project ID containing the dataset
            dataset_id: BigQuery dataset ID

        Returns:
            Dataset information dictionary or None if not found
        """
        try:
            dataset_ref = bigquery.DatasetReference(project_id, dataset_id)
            dataset = self.bq_client.get_dataset(dataset_ref)

            return {
                "project_id": project_id,
                "dataset_id": dataset_id,
                "location": dataset.location,
                "created": dataset.created.isoformat() if dataset.created else None,
                "modified": dataset.modified.isoformat() if dataset.modified else None,
                "default_table_expiration_ms": dataset.default_table_expiration_ms,
                "description": dataset.description,
                "friendly_name": dataset.friendly_name,
                "full_dataset_id": dataset.full_dataset_id,
                "labels": dict(dataset.labels) if dataset.labels else {},
            }
        except Exception as e:
            # Gracefully handle missing datasets or access issues
            error_msg = str(e).lower()
            if "not found" in error_msg or "404" in error_msg:
                print(
                    f"[Fetching BigQuery dataset metadata] ⚠️  Dataset not found or no access: {project_id}:{dataset_id}"
                )
                print(
                    "   This may be normal if the project is in a different organization"
                )
            else:
                print(
                    f"[Fetching BigQuery dataset metadata] Error getting dataset info for {project_id}:{dataset_id}: {e}"
                )
            return None

    def search_cloudaudit_sinks(self, org_id: str) -> list[dict[str, Any]]:
        """
        Search for log sinks that export CloudAudit logs to BigQuery.

        Args:
            org_id: Organization ID (numeric)

        Returns:
            List of CloudAudit log sinks that export to BigQuery with enriched information
        """
        all_sinks = self.get_org_log_sinks(org_id)
        cloudaudit_sinks = []

        for sink in all_sinks:
            # Only include BigQuery destinations (exclude Cloud Logging buckets like _Required, _Default)
            destination = sink.get("destination", "")
            if "bigquery.googleapis.com" not in destination:
                continue

            # Check if sink filter includes CloudAudit logs
            filter_str = sink.get("filter", "").lower()
            if "cloudaudit" in filter_str or "logs/activity" in filter_str:
                # Enrich with BigQuery dataset details if available
                if "bq_project_id" in sink and "bq_dataset_id" in sink:
                    bq_info = self.get_bq_dataset_info(
                        sink["bq_project_id"], sink["bq_dataset_id"]
                    )
                    if bq_info:
                        sink["bq_dataset_info"] = bq_info

                cloudaudit_sinks.append(sink)

        return cloudaudit_sinks
