# Step 1: Update kubeconfig for EKS cluster
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks --region ap-south-1 update-kubeconfig --name ${var.cluster_name}"
  }
}

# Step 2: Create 'db' namespace
resource "null_resource" "create_db_namespace" {
  depends_on = [null_resource.update_kubeconfig]

  provisioner "local-exec" {
    command = "kubectl create ns db || true"
  }
}

# Step 3: Apply standard-sc-aws.yaml
resource "null_resource" "apply_standard_sc_aws" {
  depends_on = [null_resource.create_db_namespace]

  provisioner "local-exec" {
    command = "sleep 5 && kubectl apply -f https://raw.githubusercontent.com/pavanbandaru/pulp-k8s/main/standard-sc-aws.yaml"
  }
}

# Step 4: Apply postgres.yaml
resource "null_resource" "apply_postgres_yaml" {
  depends_on = [null_resource.apply_standard_sc_aws]

  provisioner "local-exec" {
    command = "sleep 5 && kubectl apply -f https://raw.githubusercontent.com/pavanbandaru/pulp-k8s/main/postgres.yaml"
  }
}

# Step 5: Create 'pulp' namespace
resource "null_resource" "create_pulp_namespace" {
  depends_on = [null_resource.apply_postgres_yaml]

  provisioner "local-exec" {
    command = "sleep 5 && kubectl create ns pulp || true"
  }
}

# Step 6: Set kubectl context to 'pulp' namespace
resource "null_resource" "set_kube_context" {
  depends_on = [null_resource.create_pulp_namespace]

  provisioner "local-exec" {
    command = "sleep 5 && kubectl config set-context --current --namespace pulp"
  }
}

# Step 7: Install Pulp operator using Helm
resource "null_resource" "install_helm" {
  depends_on = [null_resource.set_kube_context]

  provisioner "local-exec" {
    command = "sleep 5 && helm install pulp pulp-operator/pulp-operator"
  }
}

# Step 8: Apply external-db-secret.yaml
resource "null_resource" "apply_external_db_secret" {
  depends_on = [null_resource.install_helm]

  provisioner "local-exec" {
    command = "sleep 120 && kubectl apply -f https://raw.githubusercontent.com/pavanbandaru/pulp-k8s/main/external-db-secret.yaml"
  }
}

# Step 9: Apply pulp-sample.yaml
resource "null_resource" "apply_pulp_sample" {
  depends_on = [null_resource.apply_external_db_secret]

  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/pavanbandaru/pulp-k8s/main/pulp-sample.yaml"
  }
}

variable "cluster_name" {
  description = "EKS cluster name for deploying the application"
  type        = string
}
