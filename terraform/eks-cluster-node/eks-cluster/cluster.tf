resource "aws_eks_cluster" "pulp_k8s" {
  name     = "Pulp-K8s-Terraform"
  role_arn = "arn:aws:iam::205930613551:role/k8s-cluster"

  version = "1.31"

  vpc_config {
    subnet_ids = [
      "subnet-0f6441c26324477cb",
      "subnet-0a071b233f3877bb2",
      "subnet-0b95ce320c97b82e7"
    ]
    security_group_ids      = ["sg-00b574ed3c0c0f494"]
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  # Upgrade Policy
  upgrade_policy {
    support_type = "STANDARD"
  }

  provisioner "local-exec" {
    command = "echo 'EKS Cluster Creation Started: Pulp-K8s-Terraform'"
  }
}

# Outputs
output "cluster_name" {
  value = aws_eks_cluster.pulp_k8s.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.pulp_k8s.endpoint
}