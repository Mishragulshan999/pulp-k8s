#!/bin/bash

# Define GitHub repository and token
GITHUB_REPO="mishragulshan999"
TOKEN="X-XXXXXX"

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
  # Fetch GitHub tags and created_at for the current image
  GITHUB_TAGS=$(curl -s -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/users/$GITHUB_REPO/packages/container/$IMAGE_NAME/versions" \
    | jq -r '.[] | "\(.metadata.container.tags[])\t\(.created_at)"')

  # Fetch Kubernetes deployed tags for the current image
  K8S_TAGS=$(kubectl get pods --all-namespaces -o=jsonpath='{.items[*].spec.containers[*].image}' \
    | tr ' ' '\n' | grep "$IMAGE_NAME" | cut -d ':' -f2)

  # Prepare output
  BOX_WIDTH=80
  draw_box $BOX_WIDTH
  printf "| %-75s |\n" "Image: $IMAGE_NAME"
  draw_box $BOX_WIDTH
  printf "| %-22s | %-22s | %-22s |\n" "GitHub Tag" "K8s Deployed?" "Push Date"
  draw_box $BOX_WIDTH

  # Loop through each tag and display the relevant information
  while IFS=$'\t' read -r github_tag created_at; do
    if [[ " ${K8S_TAGS[@]} " =~ " ${github_tag} " ]]; then
      printf "| %-22s | %-22s | %-22s |\n" "$github_tag" "Yes" "$created_at"
    else
      printf "| %-22s | %-22s | %-22s |\n" "$github_tag" "No" "$created_at"
    fi
  done <<< "$GITHUB_TAGS"

  draw_box $BOX_WIDTH
  echo ""
done