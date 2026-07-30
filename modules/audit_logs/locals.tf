locals {
  enable_cyngular_bigquery_export = var.enable_cyngular_bigquery_export

  # High-volume, low-value audit events from K8s/operators (leases + status updates)
  # excluded from the BigQuery export sink to reduce noise and storage cost.
  excluded_method_names = [
    "io.k8s.coordination.v1.leases.update",
    "io.k8s.coordination.v1.leases.create",
    "com.coreos.monitoring.v1.prometheuses.status.patch",
    "io.wiz.resourcescanner.v2beta1.scansources.status.update",
    "io.wiz.diskanalyzer.v1alpha1.diskscans.status.update",
    "com.dynatrace.v1beta6.dynakubes.status.update",
    "sh.keda.v1alpha1.scaledobjects.status.patch",
    "sh.gatekeeper.status.v1beta1.constraintpodstatuses.update",
    "google.cloud.apigee.v1.RuntimeService.ReportInstanceStatus",
  ]
  noisy_methods_exclusion_filter = join(" OR ", [
    for m in local.excluded_method_names : "protoPayload.methodName=\"${m}\""
  ])

  # Fix: resource_id returns full path (projects/{project}/datasets/{dataset_id}), 
  # but IAM resource expects just the dataset name/id.
  dest_dataset_id = local.enable_cyngular_bigquery_export ? module.destination_dataset[0].resource_name : var.bq_dataset_name

  # currently same permissions
  bq_cyngular_sa_permissions = [
    "roles/bigquery.dataEditor",
  ]
  bq_function_sa_permissions = [
    "roles/bigquery.dataEditor",
  ]
}