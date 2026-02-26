# ============================================================================
# PROVIDERS.TF — Tells Terraform which cloud providers to use
# ============================================================================
# Think of this like installing drivers on a Linux server.
# Before you can talk to AWS, you need the AWS "driver" (provider).
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
# Uses the credentials from: aws configure (that you ran earlier)
provider "aws" {
  region = var.aws_region
}
