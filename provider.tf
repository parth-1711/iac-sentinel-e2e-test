terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Pinned to the 4.x line because a couple of the demo violations below
      # (the standalone `acl` argument on aws_s3_bucket) were deprecated and
      # later removed from the resource schema in provider v5+.
      version = "~> 4.0"
    }
  }
}

# Dummy, non-functional credentials — this repo never runs `terraform apply`
# against real AWS. It only exists so `terraform plan` can produce a plan
# JSON for IaC Sentinel's OPA policies to evaluate in CI.
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}
