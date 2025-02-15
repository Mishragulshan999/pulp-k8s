#!/bin/bash

# Define GitHub repository and token
GITHUB_REPO="mishragulshan999"
TOKEN="X-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"

# Function to draw a box
draw_box() {
  local width=$1
  printf "%0.s-" $(seq 1 $width)
  echo ""
}

# Function to delete an image version
delete_image_version() {
  local image_name=$1
  local version_id=$2
  echo "Deleting image version: $image_name - ID: $version_id"

  curl -L -X DELETE \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/users/$GITHUB_REPO/packages/container/$image_name/versions/$version_id"

  echo "Deleted version ID: $version_id"
}

# Fetch the list of all container images from GitHub
IMAGES=$(curl -s -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/users/$GITHUB_REPO/packages?package_type=container" \
  | jq -r '.[].name')

# Process each image
for IMAGE_NAME in $IMAGES; do
  echo "Processing image: $IMAGE_NAME"

  # Fetch versions from GitHub
  IMAGE_VERSIONS=$(curl -s -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/users/$GITHUB_REPO/packages/container/$IMAGE_NAME/versions" \
    | jq -r '.[] | "\(.id) \(.metadata.container.tags[0]) \(.created_at)"' | sort -k3)

  # Fetch Kubernetes deployed tags (with full image name)
  K8S_TAGS=$(kubectl get pods --all-namespaces -o=jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | grep -E "^ghcr.io/$GITHUB_REPO/$IMAGE_NAME:")

  # Debugging: Show what tags are fetched from Kubernetes
  echo "Fetched Kubernetes tags: $K8S_TAGS"
  echo "Fetched GitHub versions: $IMAGE_VERSIONS"

  # Print comparison table
  BOX_WIDTH=80
  draw_box $BOX_WIDTH
  printf "| %-75s |\n" "Image: $IMAGE_NAME"
  draw_box $BOX_WIDTH
  printf "| %-22s | %-22s | %-22s |\n" "GitHub Tag" "K8s Deployed?" "Push Date"
  draw_box $BOX_WIDTH

  while read -r version_id tag created_at; do
    if echo "$K8S_TAGS" | grep -qE "^ghcr.io/$GITHUB_REPO/$IMAGE_NAME:$tag$"; then
      printf "| %-22s | %-22s | %-22s |\n" "$tag" "Yes" "$created_at"
    else
      printf "| %-22s | %-22s | %-22s |\n" "$tag" "No" "$created_at"
    fi
  done <<< "$IMAGE_VERSIONS"

  draw_box $BOX_WIDTH
  echo ""

   Ask for confirmation before deletion
  read -p "Do you want to proceed with deletion? (y/n): " confirm
  if [[ "$confirm" != "y" ]]; then
    echo "Skipping deletion for $IMAGE_NAME."
    continue
  fi

  # Extract IDs and tags
  TOTAL_VERSIONS=$(echo "$IMAGE_VERSIONS" | wc -l)
  DELETE_COUNT=$((TOTAL_VERSIONS - 5))

  if [[ $DELETE_COUNT -gt 0 ]]; then
    echo "Deleting $DELETE_COUNT old versions for $IMAGE_NAME..."
    echo ""

    # Delete old versions if they are not deployed in Kubernetes
    echo "$IMAGE_VERSIONS" | head -n $DELETE_COUNT | while read -r version_id tag created_at; do
      if ! echo "$K8S_TAGS" | grep -qE "^ghcr.io/$GITHUB_REPO/$IMAGE_NAME:$tag$"; then
        delete_image_version "$IMAGE_NAME" "$version_id"
      else
        echo "Skipping deletion of deployed image: $tag"
      fi
    done
  else
    echo "No old images to delete for $IMAGE_NAME."
  fi

  echo ""
done
