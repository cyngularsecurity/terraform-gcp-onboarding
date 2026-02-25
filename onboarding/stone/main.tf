module "cyngular_gcp_onboarding" {
    source = "cyngularsecurity/onboarding/gcp"

    client_name = "stone"
    client_main_location = "us-east4"
    #   version = "1.0.16"

    organization_id = "795614755097" 
    billing_account = "010722-BB2F2E-435F3D"
}

output "deployment_summary" {
  value = module.cyngular_gcp_onboarding.deployment_summary
}