#!/bin/bash

# Define GitHub repository and token
GITHUB_REPO="mishragulshan999"
TOKEN="X-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"

# Fetch the list of all container images from GitHub
IMAGES=$(curl -s -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/users/$GITHUB_REPO/packages?package_type=container" \
  | jq -r '.[].name')

# Function to draw a box
draw_box() {
  local width=$1
  printf "%0.s-" $(seq 1 $width)
  echo ""
}

# Fetch and compare tags for each image
echo "Fetching and comparing image tags..."
echo ""

for IMAGE_NAME in $IMAGES; do
  # Fetch GitHub tags for the current image
  GITHUB_TAGS=$(curl -s -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/users/$GITHUB_REPO/packages/container/$IMAGE_NAME/versions" \
  | jq -r '.[].metadata.container.tags[]')

  # Fetch Kubernetes deployed tags for the current image
  K8S_TAGS=$(kubectl get pods --all-namespaces -o=jsonpath='{.items[*].spec.containers[*].image}' \
    | tr ' ' '\n' | grep "$IMAGE_NAME" | cut -d ':' -f2)

  # Prepare output
  BOX_WIDTH=50
  draw_box $BOX_WIDTH
  printf "| %-47s |\n" "Image: $IMAGE_NAME"
  draw_box $BOX_WIDTH
  printf "| %-22s | %-22s |\n" "GitHub Tag" "K8s Deployed?"
  draw_box $BOX_WIDTH

  for github_tag in $GITHUB_TAGS; do
    if [[ " ${K8S_TAGS[@]} " =~ " ${github_tag} " ]]; then
      printf "| %-22s | %-22s |\n" "$github_tag" "Yes"
    else
      printf "| %-22s | %-22s |\n" "$github_tag" "No"
    fi
  done

  draw_box $BOX_WIDTH
  echo ""
done

