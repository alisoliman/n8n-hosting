# n8n MCP Configuration Guide

## Overview
Configure n8n to connect to the hello-world-mcp service running in the same AKS cluster.

## Service Details
- **Service Name**: `hello-world-mcp-service`
- **Namespace**: `default`
- **Port**: `8000`
- **MCP Endpoint**: `/mcp`
- **Transport**: HTTP/SSE

## Configuration Options

### Option 1: Kubernetes Internal DNS (Recommended)

Since both n8n and hello-world-mcp are in the same cluster:

**Full DNS Name (works from any namespace):**
```
http://hello-world-mcp-service.default.svc.cluster.local:8000/mcp
```

**Short DNS Name (if n8n is in the same 'default' namespace):**
```
http://hello-world-mcp-service:8000/mcp
```

### Option 2: Environment Variables

If n8n supports MCP configuration via environment variables, add to your n8n deployment:

```yaml
env:
  - name: MCP_SERVER_URL
    value: "http://hello-world-mcp-service:8000/mcp"
  - name: MCP_SERVER_NAME
    value: "Hello World MCP Server"
  - name: MCP_TRANSPORT
    value: "http"
```

### Option 3: n8n Credentials

If configuring through n8n UI:

1. **Go to**: Settings → Credentials → Add Credential
2. **Type**: HTTP Request / Generic API
3. **Base URL**: `http://hello-world-mcp-service:8000`
4. **Headers**: (usually not required for MCP)

### Option 4: HTTP Request Node

For direct HTTP requests to MCP server:

**Node Configuration:**
- **Method**: `POST`
- **URL**: `http://hello-world-mcp-service:8000/mcp`
- **Headers**:
  ```json
  {
    "Content-Type": "application/json"
  }
  ```
- **Body**: MCP protocol JSON (depends on your use case)

## Testing the Connection

### From within n8n pod:

```bash
# Get into n8n pod
kubectl exec -it <n8n-pod-name> -- /bin/sh

# Test connectivity
curl http://hello-world-mcp-service:8000/mcp

# Test DNS resolution
nslookup hello-world-mcp-service
```

### From your local machine (port-forward):

```bash
# Port forward the MCP service
kubectl port-forward service/hello-world-mcp-service 8000:8000

# Test with MCP Inspector
pip install "fastmcp[cli]"
fastmcp inspect http://localhost:8000/mcp
```

## Available MCP Tools

Your hello-world-mcp server provides these tools:

1. **hello(name: str)**
   - Greets someone by name
   - Returns: "Hello, {name}! Welcome to FastMCP on AKS!"

2. **add(a: int, b: int)**
   - Adds two numbers
   - Returns: Sum of a and b

## Network Requirements

### Same Namespace (default)
✅ No additional configuration needed - just use service name

### Different Namespace
If n8n is in a different namespace, use the full DNS:
```
http://hello-world-mcp-service.default.svc.cluster.local:8000/mcp
```

### Network Policies
If you have Network Policies enabled, ensure traffic is allowed:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-n8n-to-mcp
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: hello-world-mcp
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: <n8n-namespace>
    - podSelector:
        matchLabels:
          app: n8n
    ports:
    - protocol: TCP
      port: 8000
```

## Troubleshooting

### Connection Refused
```bash
# Check if MCP service is running
kubectl get pods -l app=hello-world-mcp
kubectl get service hello-world-mcp-service

# Check logs
kubectl logs -l app=hello-world-mcp
```

### DNS Not Resolving
```bash
# From n8n pod
nslookup hello-world-mcp-service
nslookup hello-world-mcp-service.default.svc.cluster.local

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

### Network Policy Blocking
```bash
# List network policies
kubectl get networkpolicies

# Temporarily test without policies
kubectl delete networkpolicy <policy-name>
```

## Example n8n Workflow

If using HTTP Request node in n8n:

### Call "hello" tool:
```json
POST http://hello-world-mcp-service:8000/mcp
Content-Type: application/json

{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "hello",
    "arguments": {
      "name": "n8n User"
    }
  },
  "id": 1
}
```

### Call "add" tool:
```json
POST http://hello-world-mcp-service:8000/mcp
Content-Type: application/json

{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "add",
    "arguments": {
      "a": 10,
      "b": 20
    }
  },
  "id": 2
}
```

## Additional Resources

- FastMCP Documentation: https://gofastmcp.com
- MCP Protocol Specification: https://spec.modelcontextprotocol.io
- n8n HTTP Request Documentation: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.httprequest/
