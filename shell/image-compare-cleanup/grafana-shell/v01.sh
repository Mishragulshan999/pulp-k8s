#!/bin/bash

# Define GitHub repository and token
GITHUB_REPO="mishragulshan999"
TOKEN="xxxxxxxxxxxxxxxxxxxx"

# Fetch container images from GitHub
echo "Fetching images from GitHub..."
IMAGES=$(curl -s -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/users/$GITHUB_REPO/packages?package_type=container" \
  | jq -r '.[] | {image: .name, url: .html_url}')

# Fetch deployed tags in Kubernetes
echo "Fetching deployed tags from Kubernetes..."
DEPLOYED_IMAGES=$(kubectl get pods --all-namespaces -o=jsonpath='{.items[*].spec.containers[*].image}' \
  | tr ' ' '\n')

# Prepare JSON data for visualization
OUTPUT="["
for row in $(echo "$IMAGES" | jq -c '.'); do
    IMAGE_NAME=$(echo "$row" | jq -r '.image')
    GITHUB_TAGS=$(curl -s -L \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/users/$GITHUB_REPO/packages/container/$IMAGE_NAME/versions" \
      | jq -r '.[0].metadata.container.tags[]')
    
    for tag in $GITHUB_TAGS; do
        if echo "$DEPLOYED_IMAGES" | grep -q "$IMAGE_NAME:$tag"; then
            STATUS="Deployed"
        else
            STATUS="NOT Deployed"
        fi
        OUTPUT="$OUTPUT{\"Image\":\"$IMAGE_NAME\",\"Tag\":\"$tag\",\"Status\":\"$STATUS\"},"
    done
done

# Final JSON output
OUTPUT="${OUTPUT%,}]"
echo "$OUTPUT" > output.json
echo "JSON output written to output.json"
