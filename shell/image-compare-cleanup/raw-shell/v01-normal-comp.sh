#!/bin/bash

# Define GitHub user and token
GITHUB_USER="mishragulshan999"
TOKEN="XXXXXX"

echo "Fetching all container images from GitHub..."
echo "-------------------------------------"

# Fetch all container images from GitHub
IMAGES=$(curl -s -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/users/$GITHUB_USER/packages?package_type=container" \
  | jq -r '.[].name')

if [[ -z "$IMAGES" ]]; then
  echo "No container images found in GitHub."
  exit 1
fi

for IMAGE_NAME in $IMAGES; do
  echo "Processing image: $IMAGE_NAME"

  # Fetch tags from GitHub Container Registry for the current image
  echo "Fetching tags from GitHub for $IMAGE_NAME..."
  GITHUB_TAGS=$(curl -s -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/users/$GITHUB_USER/packages/container/$IMAGE_NAME/versions" \
    | jq -r '.[0].metadata.container.tags[]')

  if [[ -z "$GITHUB_TAGS" ]]; then
    echo "No tags found on GitHub for $IMAGE_NAME."
    continue
  fi

  # Fetch deployed tags in Kubernetes
  echo "Fetching tags deployed in Kubernetes..."
  K8S_TAGS=$(kubectl get pods --all-namespaces -o=jsonpath='{.items[*].spec.containers[*].image}' \
    | tr ' ' '\n' | grep "$IMAGE_NAME" | cut -d ':' -f2)

  # Convert both GitHub and Kubernetes tags to arrays
  GITHUB_TAGS_ARRAY=($GITHUB_TAGS)
  K8S_TAGS_ARRAY=($K8S_TAGS)

  # Compare GitHub tags and show deployment status
  echo "Comparing GitHub tags with Kubernetes deployment status for $IMAGE_NAME..."
  for github_tag in "${GITHUB_TAGS_ARRAY[@]}"; do
    if [[ " ${K8S_TAGS_ARRAY[@]} " =~ " ${github_tag} " ]]; then
      echo "GitHub Tag: $github_tag - Deployed in Kubernetes"
    else
      echo "GitHub Tag: $github_tag - NOT deployed in Kubernetes"
    fi
  done
  echo "-------------------------------------"
done
