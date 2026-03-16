#!/bin/bash

# Deployment script for MCP Server to AKS
set -e

# Configuration
REGISTRY="your-registry.azurecr.io"
IMAGE_NAME="hello-world-mcp"
VERSION="${1:-latest}"
DEPLOYMENT_NAME="hello-world-mcp"

echo "🚀 Deploying MCP Server to AKS"
echo "================================"
echo "Registry: $REGISTRY"
echo "Image: $IMAGE_NAME:$VERSION"
echo ""

# Step 1: Build and push Docker image
echo "📦 Building Docker image..."
docker buildx build --platform linux/amd64 \
  -t $REGISTRY/$IMAGE_NAME:$VERSION \
  --push .

if [ $? -eq 0 ]; then
  echo "✅ Image built and pushed successfully"
else
  echo "❌ Failed to build/push image"
  exit 1
fi

# Step 2: Update deployment
echo ""
echo "🔄 Updating Kubernetes deployment..."

# Update the image in deployment.yaml if using a specific version
if [ "$VERSION" != "latest" ]; then
  kubectl set image deployment/$DEPLOYMENT_NAME \
    mcp-server=$REGISTRY/$IMAGE_NAME:$VERSION
else
  # For latest, just apply the deployment and restart
  kubectl apply -f deployment.yaml
  kubectl rollout restart deployment/$DEPLOYMENT_NAME
fi

# Step 3: Wait for rollout
echo ""
echo "⏳ Waiting for rollout to complete..."
kubectl rollout status deployment/$DEPLOYMENT_NAME --timeout=3m

if [ $? -eq 0 ]; then
  echo "✅ Deployment successful"
else
  echo "❌ Deployment failed"
  exit 1
fi

# Step 4: Show status
echo ""
echo "📊 Current Status:"
echo "=================="
kubectl get pods -l app=$DEPLOYMENT_NAME
echo ""
kubectl get service hello-world-mcp-service

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "To check logs:"
echo "  kubectl logs -l app=$DEPLOYMENT_NAME --tail=50 -f"
echo ""
echo "To test the service:"
echo "  kubectl port-forward service/hello-world-mcp-service 8000:8000"
echo "  curl http://localhost:8000/health"

