# Simple MCP Server

A FastMCP server running on Azure Kubernetes Service (AKS) with HTTP/SSE transport.

## Features

- **HTTP/SSE Transport**: Runs as an HTTP server suitable for Kubernetes deployment
- **Health Checks**: Built-in health endpoint for Kubernetes liveness/readiness probes
- **Tools**: 
  - `hello`: Greet someone by name
  - `add`: Add two numbers together
  - `health`: Health check endpoint

## Architecture

This MCP server runs in HTTP mode using uvicorn, which makes it suitable for Kubernetes deployments where STDIO transport is not available.

## Local Development

```bash
# Install dependencies using uv
uv pip install -r pyproject.toml

# Run the server
python server.py
```

The server will start on `http://localhost:8000`

## Docker Build

```bash
# Build for linux/amd64 platform
docker buildx build --platform linux/amd64 \
  -t your-registry.azurecr.io/hello-world-mcp:latest \
  --push .
```

## Kubernetes Deployment

### Prerequisites
- Azure Container Registry (ACR) access configured
- kubectl configured to access your AKS cluster

### Deploy

```bash
# Apply all resources
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Watch the deployment
kubectl get pods -l app=hello-world-mcp -w

# Check logs
kubectl logs -l app=hello-world-mcp --tail=50 -f
```

### Update Deployment

```bash
# Build and push new image
docker buildx build --platform linux/amd64 \
  -t your-registry.azurecr.io/hello-world-mcp:v2 \
  --push .

# Update deployment
kubectl set image deployment/hello-world-mcp \
  mcp-server=your-registry.azurecr.io/hello-world-mcp:v2

# Or apply the updated deployment.yaml
kubectl apply -f deployment.yaml
kubectl rollout restart deployment/hello-world-mcp
```

### Verify Health

```bash
# Port forward to access the service locally
kubectl port-forward service/hello-world-mcp-service 8000:8000

# In another terminal, test the health endpoint
curl http://localhost:8000/health
```

## Configuration

### Resource Limits
Current settings in `deployment.yaml`:
- Requests: 128Mi memory, 100m CPU
- Limits: 512Mi memory, 500m CPU

### Replicas
Default: 2 replicas for high availability

### Health Checks
- **Liveness Probe**: Checks `/health` endpoint every 30s
- **Readiness Probe**: Checks `/health` endpoint every 10s

## Troubleshooting

### Pod CrashLoopBackOff
```bash
# Check pod logs
kubectl logs -l app=hello-world-mcp --tail=100

# Check pod events
kubectl describe pod -l app=hello-world-mcp
```

### Image Pull Errors
```bash
# Verify ACR access
az acr login --name your-acr-name

# Check image exists
az acr repository show-tags --name your-acr-name --repository hello-world-mcp
```

### Health Check Failures
```bash
# Port forward and test manually
kubectl port-forward service/hello-world-mcp-service 8000:8000
curl -v http://localhost:8000/health
```

## MCP Protocol

This server uses the MCP (Model Context Protocol) with HTTP/SSE transport. Clients can connect via:
- HTTP endpoint: `http://hello-world-mcp-service:8000`
- SSE for streaming responses

## License

MIT

