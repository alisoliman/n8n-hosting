# n8n on Azure Kubernetes Service (AKS)

Step-by-step guide for deploying [n8n](https://n8n.io) on AKS with PostgreSQL, TLS via Let's Encrypt, and an optional MCP server — based on the official [n8n-io/n8n-hosting](https://github.com/n8n-io/n8n-hosting) template.

## Prerequisites

| Tool | Install |
|------|---------|
| [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) | `brew install azure-cli` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | `az aks install-cli` |
| [Helm](https://helm.sh/docs/intro/install/) | `brew install helm` |
| A domain name with DNS you control | Point an A record to the ingress IP (see Step 4) |

```bash
# Login and set subscription
az login
az account set --subscription "<your-subscription-id>"
```

## Architecture

```
Internet → nginx Ingress (TLS) → n8n Service → n8n Pod
                                                  ↓
                                          Postgres Service → Postgres Pod
                                                              ↓
                                                         PersistentVolume
```

## Quick Start (AKS)

### 1. Create an AKS cluster (skip if you have one)

```bash
RESOURCE_GROUP="n8n-rg"
CLUSTER_NAME="n8n-cluster"
LOCATION="eastus"

az group create --name $RESOURCE_GROUP --location $LOCATION

az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys

az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
```

### 2. Install nginx Ingress Controller + cert-manager

```bash
# nginx ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace --namespace ingress-nginx

# cert-manager (for automatic TLS certificates)
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --create-namespace --namespace cert-manager \
  --set crds.enabled=true
```

### 3. Configure your values

Edit these files and replace the placeholders:

| File | What to change |
|------|---------------|
| `kubernetes/postgres-secret.yaml` | `changeUser` / `changePassword` → your Postgres credentials |
| `kubernetes/n8n-ingress.yaml` | `n8n.example.com` → your domain |
| `kubernetes/n8n-deployment.yaml` | `n8n.example.com` in `WEBHOOK_URL` → your domain |
| `kubernetes/letsencrypt-prod.yaml` | `your-email@example.com` → your email (for Let's Encrypt) |

### 4. Deploy (in order)

```bash
cd kubernetes/

# Namespace first
kubectl apply -f namespace.yaml

# Secrets and config
kubectl apply -f postgres-secret.yaml
kubectl apply -f postgres-configmap.yaml

# Storage
kubectl apply -f postgres-claim0-persistentvolumeclaim.yaml
kubectl apply -f n8n-claim0-persistentvolumeclaim.yaml

# Postgres
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

# Wait for Postgres to be ready
kubectl -n n8n wait --for=condition=ready pod -l service=postgres-n8n --timeout=120s

# n8n
kubectl apply -f n8n-deployment.yaml
kubectl apply -f n8n-service.yaml

# TLS + Ingress
kubectl apply -f letsencrypt-prod.yaml
kubectl apply -f n8n-ingress.yaml
```

### 5. Point your DNS

Get the ingress external IP:

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Create an **A record** in your DNS provider: `n8n.example.com` → that IP.

### 6. Verify

```bash
# Check all pods are running
kubectl -n n8n get pods

# Check certificate was issued
kubectl -n n8n get certificate

# Open in browser
open https://n8n.example.com
```

## Other Deployment Options

| Directory | Description |
|-----------|-------------|
| [`docker-caddy/`](docker-caddy/) | Docker Compose + Caddy reverse proxy with automatic SSL |
| [`docker-compose/withPostgres/`](docker-compose/withPostgres/) | Docker Compose with PostgreSQL backend |
| [`docker-compose/withPostgresAndWorker/`](docker-compose/withPostgresAndWorker/) | Docker Compose with PostgreSQL + separate worker |
| [`docker-compose/subfolderWithSSL/`](docker-compose/subfolderWithSSL/) | Docker Compose served from a URL subfolder with SSL |
| [`simple-mcp/`](simple-mcp/) | FastMCP server for n8n on AKS ([guide](simple-mcp/README.md)) |

## Setup Notes

- All config files use **placeholder values** (`changeUser`, `n8n.example.com`). Replace them before deploying.
- Copy any `.env.example` → `.env` and fill in your details.
- `.env` files are gitignored — never commit real secrets.

## Upstream

This repo tracks the official template as a remote:

```bash
git fetch upstream
git merge upstream/main
```
