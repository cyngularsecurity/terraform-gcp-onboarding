#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "google-cloud-logging>=3.11.4",
#     "google-cloud-bigquery>=3.26.0",
#     "google-cloud-resource-manager>=1.13.1",
#     "rich>=13.9.4",
# ]
# ///
"""
GCP Log Sink Discovery Tool

This script helps discover existing GCP log sinks and BigQuery datasets
to populate Terraform variables for the terraform-gcp-onboarding module.

Usage:
    # List all accessible organizations
    uv run scripts/get_log_sink_info.py --list-orgs

    # Get log sinks for a specific organization
    uv run scripts/get_log_sink_info.py --org-id 123456789012

    # Get CloudAudit-specific log sinks (filtered)
    uv run scripts/get_log_sink_info.py --org-id 123456789012 --cloudaudit-only

    # Get specific BigQuery dataset details
    uv run scripts/get_log_sink_info.py --bq-dataset PROJECT_ID:DATASET_ID

    # Interactive mode (recommended)
    uv run scripts/get_log_sink_info.py --interactive

Requirements:
    - Authenticated with GCP (run: gcloud auth application-default login)
    - Proper IAM permissions:
        - roles/resourcemanager.organizationViewer (to list orgs)
        - roles/logging.viewer (to list log sinks)
        - roles/bigquery.dataViewer (to view dataset metadata)
"""

import argparse
import json
import sys
from typing import Any

from rich.console import Console
from rich.panel import Panel
from rich.prompt import Confirm, Prompt
from rich.table import Table
from rich.tree import Tree

from utils import GCPResourceDiscovery

console = Console()


def print_organizations(orgs: list[dict[str, Any]]) -> None:
    """Print organizations in a formatted table."""
    if not orgs:
        console.print(
            "[yellow]No organizations found or insufficient permissions[/yellow]"
        )
        console.print("\nMake sure you have:")
        console.print("  1. Run: gcloud auth application-default login")
        console.print("  2. Have roles/resourcemanager.organizationViewer permission")
        return

    table = Table(
        title="Available GCP Organizations",
        show_header=True,
        header_style="bold magenta",
    )
    table.add_column("Organization ID", style="cyan", no_wrap=True)
    table.add_column("Display Name", style="green")
    table.add_column("State", style="yellow")

    for org in orgs:
        table.add_row(org["id"], org["display_name"], org["state"])

    console.print(table)
    console.print(f"\n[dim]Found {len(orgs)} organization(s)[/dim]")


def print_log_sinks(sinks: list[dict[str, Any]], cloudaudit_only: bool = False) -> None:
    """Print log sinks in a formatted display."""
    if not sinks:
        console.print("[yellow]No log sinks found[/yellow]")
        return

    filter_text = "CloudAudit Log Sinks" if cloudaudit_only else "All Log Sinks"
    tree = Tree(f"[bold]{filter_text}[/bold]")

    for sink in sinks:
        sink_node = tree.add(f"[cyan]{sink['name']}[/cyan]")
        sink_node.add(f"[dim]Destination:[/dim] {sink['destination']}")
        sink_node.add(f"[dim]Include Children:[/dim] {sink['include_children']}")
        sink_node.add(f"[dim]Writer Identity:[/dim] {sink['writer_identity']}")

        if sink.get("filter"):
            sink_node.add(f"[dim]Filter:[/dim] {sink['filter'][:80]}...")

        if "bq_project_id" in sink:
            bq_node = sink_node.add("[green]BigQuery Details[/green]")
            bq_node.add(f"[dim]Project ID:[/dim] {sink['bq_project_id']}")
            bq_node.add(f"[dim]Dataset ID:[/dim] {sink['bq_dataset_id']}")

            if "bq_dataset_info" in sink:
                info = sink["bq_dataset_info"]
                bq_node.add(f"[dim]Location:[/dim] {info['location']}")
                bq_node.add(f"[dim]Created:[/dim] {info['created']}")
                if info.get("description"):
                    bq_node.add(f"[dim]Description:[/dim] {info['description']}")

    console.print(tree)
    console.print(f"\n[dim]Found {len(sinks)} log sink(s)[/dim]")


def print_bq_dataset(dataset_info: dict[str, Any]) -> None:
    """Print BigQuery dataset information."""
    if not dataset_info:
        console.print("[yellow]Dataset not found or insufficient permissions[/yellow]")
        return

    table = Table(title="BigQuery Dataset Information", show_header=False)
    table.add_column("Property", style="cyan", no_wrap=True)
    table.add_column("Value", style="white")

    table.add_row("Project ID", dataset_info["project_id"])
    table.add_row("Dataset ID", dataset_info["dataset_id"])
    table.add_row("Location", dataset_info["location"])
    table.add_row("Created", dataset_info["created"] or "N/A")
    table.add_row("Modified", dataset_info["modified"] or "N/A")
    table.add_row("Full Dataset ID", dataset_info["full_dataset_id"])

    if dataset_info.get("description"):
        table.add_row("Description", dataset_info["description"])

    if dataset_info.get("friendly_name"):
        table.add_row("Friendly Name", dataset_info["friendly_name"])

    if dataset_info.get("labels"):
        table.add_row("Labels", json.dumps(dataset_info["labels"], indent=2))

    console.print(table)


def generate_terraform_vars(sink: dict[str, Any]) -> str:
    """Generate Terraform variable configuration from sink information."""
    has_dataset_info = "bq_dataset_info" in sink

    config_lines = [
        "\n# =============================================================================",
        "# Configuration for existing log sink",
        "# =============================================================================",
        "# Add these to your terraform.tfvars file:",
        "",
    ]

    if not has_dataset_info:
        config_lines.extend(
            [
                "# ⚠️  Note: Could not fetch dataset details (access issue or different org)",
                "# You may need to manually verify the location and adjust values",
                "",
            ]
        )

    # Get values with defaults
    bq_project_id = sink.get("bq_project_id", "PROJECT_ID")
    bq_dataset_id = sink.get("bq_dataset_id", "DATASET_ID")

    if has_dataset_info:
        location = sink["bq_dataset_info"].get("location", "us-east4")
    else:
        location = "us-east4"  # Default, user should verify

    config_lines.extend(
        [
            "# Use existing BigQuery dataset (instead of creating a new one)",
            "existing_bigquery_dataset = {",
            f'  dataset_name = "{bq_dataset_id}"',
            f'  project_id   = "{bq_project_id}"',
            f'  location     = "{location}"'
            + ("  # Optional: Verify this location or omit to use client_main_location" if not has_dataset_info else "  # Optional: Can be omitted to use client_main_location"),
            "}",
            "",
            "# Optional: Configure organization audit log types",
            "# organization_audit_logs = {",
            "#   log_configuration = {",
            '#     "ADMIN_READ"  = true   # Track admin operations (recommended)',
            '#     "DATA_READ"   = false  # High volume, enable only if needed',
            '#     "DATA_WRITE"  = true   # Track data modifications (recommended)',
            "#   }",
            "# }",
        ]
    )

    if has_dataset_info:
        config_lines.extend(
            [
                "",
                "# Dataset metadata (for reference):",
                f"#   Created: {sink['bq_dataset_info'].get('created', 'N/A')}",
                f"#   Location: {sink['bq_dataset_info']['location']}",
            ]
        )
        if sink["bq_dataset_info"].get("description"):
            config_lines.append(
                f"#   Description: {sink['bq_dataset_info']['description']}"
            )

    return "\n".join(config_lines)


def interactive_mode() -> None:
    """Run interactive discovery mode."""
    console.print(
        Panel.fit(
            "[bold cyan]GCP Log Sink Discovery - Interactive Mode[/bold cyan]\n"
            "This tool helps you discover existing log sinks and BigQuery datasets",
            border_style="cyan",
        )
    )

    discovery = GCPResourceDiscovery()

    # Step 1: List organizations
    console.print("\n[bold]Step 1: Discovering Organizations[/bold]")
    orgs = discovery.list_organizations()
    print_organizations(orgs)

    if not orgs:
        console.print("\n[red]Cannot proceed without organization access[/red]")
        sys.exit(1)

    # Step 2: Select organization
    console.print("\n[bold]Step 2: Select Organization[/bold]")
    if len(orgs) == 1:
        selected_org = orgs[0]
        console.print(
            f"Using only available organization: [cyan]{selected_org['display_name']}[/cyan]"
        )
    else:
        org_id = Prompt.ask("Enter organization ID")
        selected_org = next((o for o in orgs if o["id"] == org_id), None)
        if not selected_org:
            console.print("[red]Invalid organization ID[/red]")
            sys.exit(1)

    # Step 3: Search for log sinks
    console.print("\n[bold]Step 3: Searching for Log Sinks[/bold]")
    with console.status("[bold green]Querying GCP APIs..."):
        sinks = discovery.search_cloudaudit_sinks(selected_org["id"])

    print_log_sinks(sinks, cloudaudit_only=True)

    if not sinks:
        console.print("\n[yellow]No CloudAudit log sinks found[/yellow]")
        if Confirm.ask("Show all log sinks?"):
            all_sinks = discovery.get_org_log_sinks(selected_org["id"])
            print_log_sinks(all_sinks, cloudaudit_only=False)
        return

    # Step 4: Generate Terraform configuration
    console.print("\n[bold]Step 4: Generate Terraform Configuration[/bold]")
    if len(sinks) == 1:
        console.print(
            f"Using only available log sink: [cyan]{sinks[0]['name']}[/cyan]"
        )
        selected_sink = sinks[0]
    else:
        sink_names = [s["name"] for s in sinks]
        sink_name = Prompt.ask("Select log sink", choices=sink_names)
        selected_sink = next(s for s in sinks if s["name"] == sink_name)

    terraform_config = generate_terraform_vars(selected_sink)
    console.print(
        Panel(terraform_config, title="Terraform Configuration", border_style="green")
    )

    client_tfvars_filename = "client_tfvars_suggestion.tfvars"
    if Confirm.ask(
        f"\nSave configuration to file [cyan]{client_tfvars_filename}[/cyan]?", default=True
    ):
        with open(client_tfvars_filename, "w") as f:
            f.write(terraform_config)
        console.print(
            f"\n[green]✓[/green] Configuration saved to: [cyan]{client_tfvars_filename}[/cyan]"
        )


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--list-orgs", action="store_true", help="List all accessible organizations"
    )
    parser.add_argument("--org-id", help="Organization ID to query")
    parser.add_argument(
        "--cloudaudit-only", action="store_true", help="Show only CloudAudit log sinks"
    )
    parser.add_argument(
        "--bq-dataset", help="Get BigQuery dataset info (format: PROJECT_ID:DATASET_ID)"
    )
    parser.add_argument(
        "--interactive", "-i", action="store_true", help="Run in interactive mode"
    )
    parser.add_argument(
        "--output-json", action="store_true", help="Output results as JSON"
    )

    args = parser.parse_args()

    # Interactive mode
    if args.interactive:
        interactive_mode()
        return

    discovery = GCPResourceDiscovery()

    # List organizations
    if args.list_orgs:
        orgs = discovery.list_organizations()
        if args.output_json:
            print(json.dumps(orgs, indent=2))
        else:
            print_organizations(orgs)
        return

    # Query specific organization
    if args.org_id:
        if args.cloudaudit_only:
            sinks = discovery.search_cloudaudit_sinks(args.org_id)
        else:
            sinks = discovery.get_org_log_sinks(args.org_id)

        if args.output_json:
            print(json.dumps(sinks, indent=2))
        else:
            print_log_sinks(sinks, cloudaudit_only=args.cloudaudit_only)

            # Offer to generate Terraform config
            if sinks and not args.output_json:
                console.print("\n" + "=" * 80)
                if len(sinks) == 1:
                    console.print(generate_terraform_vars(sinks[0]))
                else:
                    console.print(
                        "\n[dim]Tip: Use --interactive mode to generate Terraform configuration[/dim]"
                    )
        return

    # Get BigQuery dataset info
    if args.bq_dataset:
        if ":" not in args.bq_dataset:
            console.print("[red]Error: Format should be PROJECT_ID:DATASET_ID[/red]")
            sys.exit(1)

        project_id, dataset_id = args.bq_dataset.split(":", 1)
        dataset_info = discovery.get_bq_dataset_info(project_id, dataset_id)

        if args.output_json:
            print(json.dumps(dataset_info, indent=2))
        else:
            print_bq_dataset(dataset_info)
        return

    # No arguments - show help
    parser.print_help()
    console.print(
        "\n[dim]Tip: Try running with --interactive flag for guided discovery[/dim]"
    )


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        console.print("\n\n[yellow]Operation cancelled by user[/yellow]")
        sys.exit(0)
