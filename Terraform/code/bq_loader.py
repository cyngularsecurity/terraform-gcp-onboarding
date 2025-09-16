#!/usr/bin/env python3
"""
BigQuery Dataset/Table creation for multiple tables with partitioning, clustering, and retention.
Cloud Function HTTP entry point included.
"""

import logging
import json
import functions_framework
from google.cloud import bigquery
from google.api_core.exceptions import Conflict

# Import project/table configs
from config import PROJECT_ID, DATASET_ID, LOCATION, TABLE_CONFIGS


# ---------------------------
# LOGGING SETUP
# ---------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)


def ensure_dataset(client, dataset_id: str, location: str):
    """Create dataset if it does not exist."""
    dataset_ref = f"{PROJECT_ID}.{dataset_id}"
    dataset = bigquery.Dataset(dataset_ref)
    dataset.location = location
    dataset = client.create_dataset(dataset, exists_ok=True)
    logging.info("Dataset ready: %s", dataset.dataset_id)


def ensure_table(client, dataset_id: str, table_config: dict):
    """Create table if it does not exist, with schema, partitioning, clustering, and partition expiration."""
    table_ref = f"{PROJECT_ID}.{dataset_id}.{table_config['table_id']}"
    table = bigquery.Table(table_ref, schema=table_config["schema"])

    # Partitioning
    table.time_partitioning = bigquery.TimePartitioning(
        type_=bigquery.TimePartitioningType.DAY,
        field=table_config["partition_column"],
        expiration_ms=table_config["expiration_ms"]
        if table_config["expiration_ms"] > 0
        else None,
    )

    # Clustering
    if table_config["clustering_columns"]:
        table.clustering_fields = table_config["clustering_columns"]

    try:
        table = client.create_table(table)
        logging.info(
            "Created new table: %s (Partition: %s, Clustering: %s, Expiration: %s days)",
            table.table_id,
            table_config["partition_column"] or "None",
            table_config["clustering_columns"] or "None",
            table_config["expiration_ms"] / (24 * 60 * 60 * 1000)
            if table_config["expiration_ms"]
            else "None",
        )
    except Conflict:
        logging.info("Table already exists: %s", table_config["table_id"])


def main():
    """Main function to create BigQuery datasets and tables."""
    logging.info("Starting BigQuery loader script.")
    client = bigquery.Client(project=PROJECT_ID)

    # Ensure dataset
    ensure_dataset(client, DATASET_ID, LOCATION)

    # Ensure tables
    for table_config in TABLE_CONFIGS:
        ensure_table(client, DATASET_ID, table_config)

    logging.info("Script completed successfully.")


@functions_framework.http
def http_trigger(request):
    """
    HTTP Cloud Function entry point.
    
    Calls the BigQuery loader to ensure datasets and tables are created.
    
    Returns:
        JSON response with status and message
    """
    logging.info("Cloud Function triggered via HTTP")
    
    try:
        # Call the main BigQuery loader function
        main()
        
        response = {
            "status": "success",
            "message": "BigQuery tables created/verified successfully"
        }
        logging.info("Function completed successfully")
        return json.dumps(response), 200, {"Content-Type": "application/json"}
        
    except Exception as e:
        logging.error(f"Function failed: {str(e)}")
        
        error_response = {
            "status": "error", 
            "message": f"Failed to create/verify BigQuery tables: {str(e)}"
        }
        return json.dumps(error_response), 500, {"Content-Type": "application/json"}


if __name__ == "__main__":
    main()