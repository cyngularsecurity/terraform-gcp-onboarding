#!/usr/bin/env python3
"""
BigQuery Dataset/Table creation and JSON insertion script with partitioning, clustering, and retention.

This script:
1. Ensures a dataset exists (creates if missing).
2. Ensures a table exists with a defined schema + partitioning + optional clustering + partition expiration.
3. Inserts JSON rows into the table.

Author: Cyngular (example)
"""

import logging
from google.cloud import bigquery
from google.api_core.exceptions import Conflict

# ---------------------------
# CONFIGURATION
# ---------------------------
PROJECT_ID = "your_project_id"
DATASET_ID = "my_dataset"
TABLE_ID = "my_table"
LOCATION = "US"

# Partitioning and clustering
PARTITION_COLUMN = "created_at"        # Must exist in schema (TIMESTAMP/DATE/DATETIME)
CLUSTERING_COLUMNS = ["name", "age"]   # Leave [] for no clustering
PARTITION_EXPIRATION_MS = 90 * 24 * 60 * 60 * 1000  # 90 days

# Schema definition
SCHEMA = [
    bigquery.SchemaField("name", "STRING", mode="REQUIRED"),
    bigquery.SchemaField("age", "INT64", mode="NULLABLE"),
    bigquery.SchemaField("created_at", "TIMESTAMP", mode="NULLABLE"),
]

# Example JSON rows
ROWS_TO_INSERT = [
    {"name": "Alice", "age": 30, "created_at": "2025-08-28T10:15:00Z"},
    {"name": "Bob", "age": 25, "created_at": "2025-08-28T22:47:59Z"},
]

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


def ensure_table(client, dataset_id: str, table_id: str, schema, partition_column: str,
                 clustering_columns: list, expiration_ms: int):
    """Create table if it does not exist, with schema, partitioning, clustering, and partition expiration."""
    table_ref = f"{PROJECT_ID}.{dataset_id}.{table_id}"
    table = bigquery.Table(table_ref, schema=schema)

    # Partitioning
    table.time_partitioning = bigquery.TimePartitioning(
        type_=bigquery.TimePartitioningType.DAY,
        field=partition_column,
        expiration_ms=expiration_ms if expiration_ms > 0 else None
    )

    # Clustering (only if defined)
    if clustering_columns:
        table.clustering_fields = clustering_columns

    try:
        table = client.create_table(table)
        logging.info(
            "Created new table: %s (Partition: %s, Clustering: %s, Expiration: %s days)",
            table.table_id,
            partition_column,
            clustering_columns or "None",
            expiration_ms / (24 * 60 * 60 * 1000) if expiration_ms else "None"
        )
    except Conflict:
        logging.info("Table already exists: %s", table_id)


def insert_rows(client, dataset_id: str, table_id: str, rows: list):
    """Insert JSON rows into the table."""
    table_ref = f"{PROJECT_ID}.{dataset_id}.{table_id}"

    errors = client.insert_rows_json(table_ref, rows)
    if not errors:
        logging.info("Inserted %d rows successfully.", len(rows))
    else:
        logging.error("Insert errors: %s", errors)


def main():
    logging.info("Starting BigQuery loader script.")
    client = bigquery.Client(project=PROJECT_ID)

    # Step 1: Ensure dataset
    ensure_dataset(client, DATASET_ID, LOCATION)

    # Step 2: Ensure table with schema + partitioning + clustering + expiration
    ensure_table(client, DATASET_ID, TABLE_ID, SCHEMA, PARTITION_COLUMN, CLUSTERING_COLUMNS, PARTITION_EXPIRATION_MS)

    # Step 3: Insert rows
    insert_rows(client, DATASET_ID, TABLE_ID, ROWS_TO_INSERT)

    logging.info("Script completed successfully.")


if __name__ == "__main__":
    main()