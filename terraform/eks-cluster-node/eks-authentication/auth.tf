resource "null_resource" "update_authentication_mode" {
  provisioner "local-exec" {
    command = <<EOT
      aws eks update-cluster-config \
        --name ${var.cluster_name} \
        --region ap-south-1 \
        --access-config authenticationMode=API_AND_CONFIG_MAP
      # Sleep for 2 minutes (120 seconds)
      sleep 120
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}