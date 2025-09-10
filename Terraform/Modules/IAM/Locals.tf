locals {
  cyngular_access_permissions = [
    "compute.images.list",
    "iam.roles.list",
    "iam.roles.get"
  ]

  # List of roles to be granted to the service account
  cyngular_access_roles = [
    # "roles/compute.imageUser",
    "roles/compute.admin",
    "roles/compute.networkUser",
    "roles/storage.admin",

    "roles/browser",
    "roles/viewer",

    "roles/cloudtrace.user",

    "roles/dns.reader",
    "roles/artifactregistry.reader",

    "roles/iam.securityReviewer",

    "roles/storage.objectViewer",
    "roles/bigquery.dataViewer",
    "roles/appengine.appViewer",

    "roles/compute.viewer",
    "roles/logging.viewer",
    "roles/monitoring.viewer",
    "roles/cloudsql.viewer",
    "roles/pubsub.viewer",
    "roles/container.viewer",
    "roles/cloudfunctions.viewer",
    "roles/cloudkms.viewer",
    "roles/secretmanager.viewer",
    "roles/cloudasset.viewer",
    "roles/networkmanagement.viewer",
    "roles/datastore.viewer",
    "roles/vpcaccess.viewer",
    "roles/cloudscheduler.viewer",

    # "roles/bigtable.reader",

    # "roles/servicenetworking.networksViewer",

    # "roles/redis.viewer",
    # "roles/memcache.viewer",
    # "roles/aiplatform.viewer",
    # "roles/cloudbuild.builds.viewer",
    # "roles/firebase.viewer",
    # "roles/run.viewer",
    # "roles/spanner.viewer",
    # "roles/memcache.viewer"
  ]
}