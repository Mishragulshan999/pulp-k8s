#!/bin/bash

# Define Variables
pulp_server="pulpartifactory.site"
pulp_username="admin"  # change this to your actual username
pulp_password="vs3K4CRQ8O21aloFvrqKQz4GUBxW3Qhl"  # updated password
image_name="busybox"
image_tag="v1"
namespace="busybox"

# Function to display a message
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to print section heading in a box
print_heading() {
    echo -e "\n###########################"
    echo -e "# \033[1;34m$1\033[0m #"
    echo -e "###########################"
}

########################################
# Part 1: Push Image to Pulp Registry #
########################################

print_heading "Part 1: Push Image to Pulp Registry"

# Login to Docker registry
print_heading "Docker Login"
log_message "Logging into Docker registry $pulp_server..."
docker login $pulp_server -u $pulp_username -p $pulp_password
if [ $? -ne 0 ]; then
    log_message "Docker login failed!"
    exit 1
fi
log_message "Docker login successful."

# Pull the image
print_heading "Pull Image"
log_message "Pulling image: $image_name..."
docker pull $image_name
if [ $? -ne 0 ]; then
    log_message "Failed to pull image $image_name."
    exit 1
fi
log_message "Image $image_name pulled successfully."

# Tag the image
print_heading "Tag Image"
log_message "Tagging image $image_name as $pulp_server/$image_name:$image_tag..."
docker tag $image_name $pulp_server/$image_name:$image_tag
if [ $? -ne 0 ]; then
    log_message "Failed to tag image."
    exit 1
fi
log_message "Image tagged successfully."

# Push the image
print_heading "Push Image"
log_message "Pushing image to $pulp_server..."
docker push $pulp_server/$image_name:$image_tag
if [ $? -ne 0 ]; then
    log_message "Failed to push image."
    exit 1
fi
log_message "Image pushed successfully."

############################################
# Part 2: Pull Image & Create Pod in K8s  #
############################################

print_heading "Part 2: Pull Image & Deploy in Kubernetes"

# Create namespace if not exists
print_heading "Create Namespace"
kubectl get namespace $namespace >/dev/null 2>&1
if [ $? -ne 0 ]; then
    log_message "Namespace '$namespace' not found. Creating..."
    kubectl create namespace $namespace
    log_message "Namespace '$namespace' created."
else
    log_message "Namespace '$namespace' already exists."
fi

# Create Pod using the pulled image
print_heading "Deploy Pod"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: busybox-pod
  namespace: $namespace
spec:
  containers:
  - name: busybox
    image: $pulp_server/$image_name:$image_tag
    command: ["sleep", "3600"]
EOF

log_message "Pod 'busybox-pod' created in namespace '$namespace'."

print_heading "Sanity Test Completed"
log_message "Sanity test completed successfully."
