# excalibase-infra

Kubernetes infrastructure for [excalibase.io](https://excalibase.io) — public playground for Excalibase GraphQL and REST APIs.

## Cluster

| Node | IP | Role |
|---|---|---|
| vmi3151903 | 185.227.135.251 | control-plane + etcd (master) |
| vmi3157657 | 46.250.231.155 | control-plane + etcd |
| vmi3157658 | 46.250.231.158 | control-plane + etcd |

- **Kubernetes:** RKE2 v1.34.5
- **OS:** Ubuntu 24.04 LTS
- **Specs per node:** 6 vCPU AMD EPYC / 11GB RAM / 96GB disk

## Stack

| Service | URL | Namespace |
|---|---|---|
| Excalibase GraphQL | api.excalibase.io | excalibase |
| Grafana | grafana.excalibase.io | monitoring |
| SonarQube | sonar.excalibase.io | sonarqube |
| ArgoCD | argocd.excalibase.io | argocd |
| PostgreSQL (CNPG) | internal | postgres |

## Setup Order

Run these in order on the master node (185.227.135.251):

```bash
# 1. RKE2 master node
bash setup/01-rke2-master.sh

# 2. On each additional control-plane node
NODE_IP=<ip> MASTER_IP=185.227.135.251 TOKEN=<token> bash setup/02-rke2-control-plane.sh

# 3. Firewall (run on all nodes, adjust IPs)
NODE2_IP=46.250.231.155 NODE3_IP=46.250.231.158 bash setup/03-firewall.sh

# 4. Helm
bash setup/04-helm.sh

# 5. cert-manager + Let's Encrypt
cd charts/cert-manager && bash install.sh

# 6. CNPG + PostgreSQL
S3_ACCESS_KEY=<key> S3_SECRET_KEY=<secret> bash charts/cnpg/install.sh

# 7. Monitoring (Prometheus + Grafana + Loki)
cd charts/monitoring && bash install.sh

# 8. SonarQube
cd charts/sonarqube && bash install.sh

# 9. ArgoCD
cd charts/argocd && bash install.sh
```

## GitOps — Deploying Apps with ArgoCD

ArgoCD watches this repo. Each app has its own Application manifest in `charts/argocd/`.

### Adding a new app

1. Make sure the app repo has a Helm chart (e.g. `helm/my-app/`)
2. Create `charts/argocd/app-my-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/excalibase/my-app.git
    targetRevision: HEAD
    path: helm/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: excalibase
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

3. Apply it: `kubectl apply -f charts/argocd/app-my-app.yaml`

ArgoCD will auto-sync on every commit to the app repo.

### Triggering a new deployment

ArgoCD detects changes to the Helm chart. To deploy a new image version, the app's CD pipeline should update `image.tag` in `values.yaml` and commit it back to the repo.

## DNS Setup

Point the following to **185.227.135.251** in Cloudflare (proxy enabled):

```
*.excalibase.io   A   185.227.135.251
```

Or individual records:
```
api.excalibase.io       A   185.227.135.251
grafana.excalibase.io   A   185.227.135.251
sonar.excalibase.io     A   185.227.135.251
argocd.excalibase.io    A   185.227.135.251
```

> **ArgoCD** is restricted to your IP via Cloudflare Access Pro rule.

## CNPG Notes

- 3 replicas, one per node (enforced via topologyKey)
- `pg_stat_statements` enabled for query monitoring
- Grafana dashboard: CloudNativePG (gnetId: 20417)
- Daily S3 backups at 2am → `s3://excalibase-dev-backup/asian/`
- Storage: `local-path`
- To rebalance after adding nodes: `kubectl cnpg restart postgres -n postgres`

## Resource Sizing (per node: 6 vCPU / 11GB)

| Component | CPU req | RAM req |
|---|---|---|
| RKE2 + etcd + kubelet | 500m | 1.5Gi |
| CNPG instance | 1000m | 1Gi |
| Prometheus + Grafana + Loki | 300m | 1Gi |
| SonarQube | 500m | 2Gi |
| ArgoCD | 400m | 512Mi |
| Excalibase pods | 250m | 512Mi |
| **Total requests** | **~2.9 CPU** | **~6.5Gi** |

## Firewall Rules (UFW)

| Port | Access | Purpose |
|---|---|---|
| 22 | Public | SSH |
| 80 | Public | HTTP (ACME challenge) |
| 443 | Public | HTTPS |
| 6443 | Public | Kubernetes API |
| 9345 | Public | RKE2 node join |
| 2379 | Node IPs only | etcd client |
| 2380 | Node IPs only | etcd peer |
| 10250 | Node IPs only | kubelet |
| 8472/4789 | Node IPs only | Canal VXLAN (CNI) |
