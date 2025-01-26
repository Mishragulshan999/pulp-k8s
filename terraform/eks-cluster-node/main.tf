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

# EKS Cluster creation (Step 1)
module "eks_cluster" {
  source = "./eks-cluster"
}

# Change Authentication Mode (Step 2)
module "eks_auth_mode" {
  source       = "./eks-authentication"
  cluster_name = module.eks_cluster.cluster_name

  depends_on = [module.eks_cluster]
}

# Create Node Group (Step 3)
module "eks_node_group" {
  source       = "./eks-node-group"
  cluster_name = module.eks_cluster.cluster_name

  depends_on = [module.eks_auth_mode]
}