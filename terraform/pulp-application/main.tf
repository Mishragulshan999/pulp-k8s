terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "ap-south-1"
}

# Deploy Application (Step 4)
module "eks_application" {
  source       = "./eks-application"
  cluster_name = "Pulp-K8s-Terraform"
}
