# n8n Self-Hosting

Ready-to-use configurations for self-hosting [n8n](https://n8n.io) — based on the official [n8n-io/n8n-hosting](https://github.com/n8n-io/n8n-hosting) template with additional Kubernetes and MCP server setups.

## Deployment Options

| Directory | Description |
|-----------|-------------|
| [`docker-caddy/`](docker-caddy/) | Docker Compose + Caddy reverse proxy with automatic SSL |
| [`docker-compose/withPostgres/`](docker-compose/withPostgres/) | Docker Compose with PostgreSQL backend |
| [`docker-compose/withPostgresAndWorker/`](docker-compose/withPostgresAndWorker/) | Docker Compose with PostgreSQL + separate worker process |
| [`docker-compose/subfolderWithSSL/`](docker-compose/subfolderWithSSL/) | Docker Compose served from a URL subfolder with SSL |
| [`kubernetes/`](kubernetes/) | Full Kubernetes manifests — deployment, service, ingress, cert-manager, Postgres |
| [`simple-mcp/`](simple-mcp/) | FastMCP server for n8n with Dockerfile and K8s manifests |

## Quick Start

### Docker Compose (simplest)

```bash
cd docker-compose/withPostgres
cp .env .env.local        # edit with your credentials
docker compose up -d
```

### Kubernetes

```bash
# 1. Update placeholder values
vi kubernetes/postgres-secret.yaml    # set real credentials
vi kubernetes/n8n-ingress.yaml        # set your domain
vi kubernetes/letsencrypt-prod.yaml   # set your email

# 2. Deploy
kubectl apply -f kubernetes/
```

### MCP Server

See [`simple-mcp/README.md`](simple-mcp/README.md) for setup instructions.

## Setup

All config files use **placeholder values** (e.g. `changeUser`, `n8n.example.com`). Before deploying:

1. Search for placeholders and replace with your real values
2. Copy any `.env.example` → `.env` and fill in your details
3. Never commit real secrets — `.env` files are gitignored

## Scripts

| Script | Purpose |
|--------|---------|
| [`scripts/scrub.sh`](scripts/scrub.sh) | Sanitize the repo — replaces any real secrets with safe placeholders. Idempotent. |

## Upstream

This repo tracks the official template as a remote:

```bash
git remote -v
# origin    → your private copy
# upstream  → https://github.com/n8n-io/n8n-hosting.git

# Pull upstream updates
git fetch upstream
git merge upstream/main
```
