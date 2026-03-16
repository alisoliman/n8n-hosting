# Kubernetes Manifests for n8n

All manifests target the `n8n` namespace. See the [root README](../README.md) for the full AKS deployment guide.

## Manifest Reference

Apply in this order:

| # | File | Purpose |
|---|------|---------|
| 1 | `namespace.yaml` | Creates the `n8n` namespace |
| 2 | `postgres-secret.yaml` | Postgres credentials (⚠️ edit before applying) |
| 3 | `postgres-configmap.yaml` | Init script that creates the non-root DB user |
| 4 | `postgres-claim0-persistentvolumeclaim.yaml` | 300Gi PVC for Postgres data |
| 5 | `n8n-claim0-persistentvolumeclaim.yaml` | 2Gi PVC for n8n data |
| 6 | `postgres-deployment.yaml` | Postgres 11 deployment |
| 7 | `postgres-service.yaml` | Headless service for Postgres |
| 8 | `n8n-deployment.yaml` | n8n deployment (⚠️ edit `WEBHOOK_URL` domain) |
| 9 | `n8n-service.yaml` | LoadBalancer service for n8n |
| 10 | `letsencrypt-prod.yaml` | cert-manager ClusterIssuer (⚠️ edit email) |
| 11 | `n8n-ingress.yaml` | Ingress with TLS (⚠️ edit domain) |

## Placeholders to Replace

```bash
# Find all placeholders
grep -rn 'changeUser\|changePassword\|n8n\.example\.com\|your-email@example\.com' .
```

| Placeholder | File(s) | Replace with |
|-------------|---------|-------------|
| `changeUser` | `postgres-secret.yaml` | Your Postgres username |
| `changePassword` | `postgres-secret.yaml` | Your Postgres password |
| `n8n.example.com` | `n8n-ingress.yaml`, `n8n-deployment.yaml` | Your domain |
| `your-email@example.com` | `letsencrypt-prod.yaml` | Your email for Let's Encrypt |

## Requirements

These must be installed in your cluster **before** applying the ingress/TLS manifests:

- [nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/) — routes traffic to n8n
- [cert-manager](https://cert-manager.io/) — automates TLS certificate issuance

See the [root README](../README.md#2-install-nginx-ingress-controller--cert-manager) for install commands.

## Useful Commands

```bash
# Check pod status
kubectl -n n8n get pods

# View n8n logs
kubectl -n n8n logs -l service=n8n --tail=50 -f

# View Postgres logs
kubectl -n n8n logs -l service=postgres-n8n --tail=50 -f

# Restart n8n after config changes
kubectl -n n8n rollout restart deployment/n8n

# Check TLS certificate status
kubectl -n n8n describe certificate n8n-tls

# Port-forward for local access (skip ingress)
kubectl -n n8n port-forward svc/n8n 5678:5678
# Then open http://localhost:5678
```

## Troubleshooting

**Pod stuck in Pending** — check PVC binding: `kubectl -n n8n get pvc`

**n8n CrashLoopBackOff** — usually Postgres isn't ready yet. Check: `kubectl -n n8n logs -l service=n8n`

**Certificate not issuing** — check cert-manager logs: `kubectl -n cert-manager logs -l app=cert-manager`

**502 Bad Gateway** — n8n pod may not be ready. Check: `kubectl -n n8n get pods` and ensure the n8n service selector matches.
