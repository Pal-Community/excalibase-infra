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
| Excalibase GraphQL | api.excalibase.io/graphql | excalibase |
| Excalibase REST | api.excalibase.io/rest | excalibase |
| Grafana | grafana.excalibase.io | monitoring |
| Jenkins | jenkins.excalibase.io | jenkins |
| PostgreSQL (CNPG) | internal | postgres |

## Setup Order

Run these in order on the master node (185.227.135.251):

```bash
# 1. RKE2 already installed. For new clusters:
bash setup/01-rke2-master.sh

# 2. On each additional control-plane node:
NODE_IP=<ip> MASTER_IP=185.227.135.251 TOKEN=<token> bash setup/02-rke2-control-plane.sh

# 3. Firewall (run on master, adjust IPs for other nodes too)
NODE2_IP=46.250.231.155 NODE3_IP=46.250.231.158 bash setup/03-firewall.sh

# 4. Helm
bash setup/04-helm.sh

# 5. cert-manager + Let's Encrypt
cd charts/cert-manager && bash install.sh

# 6. CNPG + PostgreSQL
cd charts/cnpg && bash install.sh

# 7. Monitoring (Prometheus + Grafana + Loki)
cd charts/monitoring && bash install.sh

# 8. Jenkins
cd charts/jenkins && bash install.sh

# 9. Excalibase
kubectl apply -f charts/excalibase/deploy.yaml
```

## DNS Setup

Point the following to **185.227.135.251** in Cloudflare:

```
*.excalibase.io   A   185.227.135.251
```

Or individual records:
```
api.excalibase.io       A   185.227.135.251
grafana.excalibase.io   A   185.227.135.251
jenkins.excalibase.io   A   185.227.135.251
```

Enable **Cloudflare proxy** on all records for DDoS protection.

## CNPG Notes

- 3 replicas, one per node (enforced via topologyKey)
- `pg_stat_statements` enabled for query monitoring
- Custom Prometheus metrics for slow query tracking
- Grafana dashboard: CloudNativePG (gnetId: 20417)
- Storage: `local-path` (RKE2 built-in)
- To restart and rebalance after adding nodes: `kubectl cnpg restart postgres -n postgres`

## Resource Sizing (per node: 6 vCPU / 11GB)

| Component | CPU req | RAM req |
|---|---|---|
| RKE2 + etcd + kubelet | 500m | 1.5Gi |
| CNPG instance | 1000m | 1Gi |
| Prometheus + Grafana + Loki | 300m | 1Gi |
| Jenkins controller | 200m | 256Mi |
| Excalibase pods | 400m | 512Mi |
| **Total requests** | **~2.4 CPU** | **~4.3Gi** |

## Firewall Rules (UFW)

| Port | Access | Purpose |
|---|---|---|
| 22 | Public | SSH |
| 80 | Public | HTTP |
| 443 | Public | HTTPS |
| 6443 | Public | Kubernetes API |
| 9345 | Public | RKE2 node join |
| 2379 | Node IPs only | etcd client |
| 2380 | Node IPs only | etcd peer |
| 10250 | Node IPs only | kubelet |
