terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.45.2"
      # version = "7.14.1"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "5.45.2"
      # version = "7.14.1"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.7.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.13.1"
    }
  }
}