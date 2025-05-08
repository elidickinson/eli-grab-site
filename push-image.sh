#!/bin/bash
# Manual build script for local use when GitHub Actions workflow fails or for testing.
# Normally, GitHub Actions should handle building and publishing the image.

# Check if container-builder exists
if ! docker buildx inspect container-builder &>/dev/null; then
  echo "Creating container-builder for multi-architecture builds..."
  docker buildx create --name container-builder --driver docker-container
fi

# Build for both architectures and push to GitHub Container Registry
echo "Building multi-architecture image and pushing to GitHub Container Registry..."
docker buildx build --builder container-builder --platform linux/amd64,linux/arm64 \
  -t ghcr.io/elidickinson/grabsite:latest \
  --push ./grabsite

echo "Build complete and pushed to GitHub Container Registry"
