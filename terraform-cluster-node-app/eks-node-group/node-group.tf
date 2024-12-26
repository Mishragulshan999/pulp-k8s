# Step 1: Create EKS Node Group
resource "aws_eks_node_group" "pulp_k8s_node_group" {
  cluster_name    = var.cluster_name
  node_group_name = "Pulp-K8s-Node"
  node_role_arn   = "arn:aws:iam::205930613551:role/Admin"

  subnet_ids = [
    "subnet-0f6441c26324477cb",
    "subnet-0a071b233f3877bb2",
    "subnet-0b95ce320c97b82e7"
  ]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 1
  }

  instance_types = ["t3.medium"]
  disk_size      = 20

  remote_access {
    ec2_ssh_key               = "Pulp-K8s-mumbai"
    source_security_group_ids = ["sg-00b574ed3c0c0f494"]
  }

  # The instance metadata options cannot be configured directly in the node group resource
  # Therefore, we will handle it in a separate step using a null_resource
  provisioner "local-exec" {
    command = "echo 'Node Group Pulp-K8s-Node Created'"
  }
}

# Step 2: Fetch EC2 Instance IDs from the Node Group
data "aws_instances" "pulp_k8s_instances" {
  filter {
    name = "tag:eks:nodegroup-name"
    values = [aws_eks_node_group.pulp_k8s_node_group.node_group_name]
  }

  filter {
    name = "instance-state-name"
    values = ["running"]
  }
}

# Step 3: Modify Instance Metadata Options (IMDSv2)
resource "null_resource" "modify_instance_metadata" {
  depends_on = [aws_eks_node_group.pulp_k8s_node_group]

  provisioner "local-exec" {
    command = <<EOT
      for instance_id in ${join(" ", data.aws_instances.pulp_k8s_instances.ids)}; do
        aws ec2 modify-instance-metadata-options \
          --instance-id $instance_id \
          --http-tokens optional \
          --http-endpoint enabled
      done
    EOT
  }
}

# Step 4: Install Add-ons
# Add-on 1: VPC CNI
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = var.cluster_name
  addon_name   = "vpc-cni"

  depends_on = [aws_eks_node_group.pulp_k8s_node_group] # Ensure node group is created first

  provisioner "local-exec" {
    command = "echo 'VPC CNI Add-on Installation Started'"
  }
}

# Add-on 2: Kube Proxy
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = var.cluster_name
  addon_name   = "kube-proxy"

  depends_on = [aws_eks_node_group.pulp_k8s_node_group] # Ensure node group is created first

  provisioner "local-exec" {
    command = "echo 'Kube-Proxy Add-on Installation Started'"
  }
}

# Add-on 3: EBS CSI Driver
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = var.cluster_name
  addon_name   = "aws-ebs-csi-driver"

  depends_on = [aws_eks_node_group.pulp_k8s_node_group] # Ensure node group is created first

  provisioner "local-exec" {
    command = "echo 'EBS CSI Driver Add-on Installation Started'"
  }
}

# Add-on 4: CoreDNS
resource "aws_eks_addon" "coredns" {
  cluster_name = var.cluster_name
  addon_name   = "coredns"

  depends_on = [aws_eks_node_group.pulp_k8s_node_group] # Ensure node group is created first

  provisioner "local-exec" {
    command = "echo 'CoreDNS Add-on Installation Started'"
  }
}

# Variable for Cluster Name
variable "cluster_name" {
  description = "EKS cluster name for the node group and add-ons"
  type        = string
}
