# terraform {
#   backend "gcs" {
#     bucket  = "BUCKET_NAME"
#     prefix  = "PATH/TO/STATEFILE"
#   }
# }

terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.45.2"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "5.45.2"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.7.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.13.1"
    }
  }
}