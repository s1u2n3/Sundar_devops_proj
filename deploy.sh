#!/bin/bash

set -e

IMAGE_NAME="sund123/prod"
IMAGE_TAG="latest"

echo "Pulling production image..."
docker pull ${IMAGE_NAME}:${IMAGE_TAG}

echo "Stopping existing application..."
docker compose down || true

echo "Starting production application..."
IMAGE_NAME=${IMAGE_NAME} IMAGE_TAG=${IMAGE_TAG} docker compose up -d

echo "Application deployed successfully."
docker ps