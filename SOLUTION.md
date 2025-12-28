# Solution Design Document

## Overview

This document outlines the architecture and design decisions for a cloud-native Kubernetes deployment platform using Azure AKS, GitOps principles with ArgoCD, and Infrastructure as Code with Terraform.

---

## What's Currently Implemented

### Infrastructure (Terraform)

| Component | Details |
|-----------|---------|
| **AKS Cluster** | 2x Standard_D2s_v6 nodes, Azure CNI networking, SystemAssigned managed identity |
| **Virtual Network** | 10.0.0.0/16 CIDR with public (10.0.1.0/24) and private (10.0.2.0/24) subnets |
| **NAT Gateway** | Provides outbound internet for private subnet nodes |
| **NSGs** | Private NSG (VNet internal + HTTP/HTTPS allow); Public NSG created but unused |
| **Public Subnet** | Provisioned for future use (App Gateway, Bastion) but no resources deployed |
| **ArgoCD** | Deployed via Helm, LoadBalancer service with Azure DNS label |

### Application (3-Tier Helm Chart)

| Component | Implementation | Details |
|-----------|----------------|---------|
| **Frontend** | Nginx | 2 replicas, LoadBalancer service, reverse proxy to backend |
| **Backend** | Flask API | 2 replicas, ClusterIP service, REST API with PostgreSQL |
| **Database** | PostgreSQL | 1 replica, ClusterIP service, 1Gi PVC for persistence |
| **Secrets** | K8s Secret | PostgreSQL credentials stored as Kubernetes Secret |

### CI/CD Pipeline (GitHub Actions)

| Feature | Implementation | Details |
|---------|----------------|---------|
| **Selective Builds** | paths-filter | Only builds changed components (frontend/backend) |
| **Container Registry** | DockerHub | Public registry (ivbosk/demo_frontend, ivbosk/demo_backend) |
| **Image Tagging** | Git SHA | Images tagged with commit SHA + latest |
| **GitOps Integration** | Auto-commit | Pipeline updates values.yaml and commits back to repo |
| **ArgoCD Sync** | Auto-sync | ArgoCD polls repo and deploys changes automatically |

### Networking & DNS

| Feature | Implementation | Details |
|---------|----------------|---------|
| **Frontend DNS** | Azure DNS Label | demo-app-ivbosk.australiacentral.cloudapp.azure.com |
| **ArgoCD DNS** | Azure DNS Label | argocd-ivbosk.australiacentral.cloudapp.azure.com |
| **Load Balancers** | Azure LB | Auto-provisioned by AKS for LoadBalancer services |

---

## Architecture Decisions & Trade-offs

### 1. Cloud Provider: Azure AKS

**Decision:** Use Azure AKS over AWS EKS or GKE

**Rationale:**
- AKS control plane is **free**
- Simpler managed identity integration
- Azure CNI provides native VNet pod networking

**Trade-offs Accepted:**
| Pro | Con |
|-----|-----|
| Free control plane | Smaller community vs AWS |
| Native Azure integration | More complex RBAC assignments |
| Azure CNI performance | Less mature multi-region support |

### 2. Container Registry: DockerHub (not ACR)

**Decision:** Use public DockerHub instead of Azure Container Registry

**Rationale:**
- Simplifies setup (no ACR role assignments needed)
- Cross-cloud portability
- Free tier sufficient for POC

**Trade-offs Accepted:**
| Pro | Con |
|-----|-----|
| No Azure RBAC complexity | No private endpoint (images public) |
| Works with any K8s cluster | Rate limiting on pulls |
| Free | No vulnerability scanning |

**Note:** ACR code is preserved but commented out in ci-cd.yaml and values.yaml for easy migration.

### 3. Network Architecture: Private Subnet + NAT Gateway

**Decision:** Place AKS nodes in private subnet with NAT Gateway for outbound

**Rationale:**
- Nodes have no public IPs (defense in depth)
- Controlled egress point for auditing
- Aligns with enterprise security patterns

**Trade-offs Accepted:**
| Pro | Con |
|-----|-----|
| No direct node exposure | NAT Gateway cost (~$35/month) |
| Single egress point | Added complexity |
| Audit-friendly | Could use simpler public subnet |

### 4. NSG Configuration

**Decision:** Allow HTTP/HTTPS explicitly, deny other internet traffic

**Current Rules (Private NSG):**
```
Priority 100: Allow VNet ↔ VNet (all)
Priority 110: Allow HTTP (80) inbound
Priority 120: Allow HTTPS (443) inbound  
Priority 200: Deny Internet inbound (this should be redundant)
```

**Trade-offs Accepted:**
| Pro | Con |
|-----|-----|
| LoadBalancer services work | Broad HTTP/HTTPS allow |
| Simple rule set | Not application-specific |
| Easy troubleshooting | NodePort range not restricted |

### 5. GitOps: ArgoCD

**Decision:** Use ArgoCD for continuous deployment

**Rationale:**
- Git as single source of truth
- Automatic sync and self-healing
- Visual UI for deployment status
- Product maturity

**Trade-offs Accepted:**
| Pro | Con |
|-----|-----|
| Declarative deployments | Additional cluster component |
| Drift detection | Learning curve for teams |
| Rollback via git revert | Secrets in git (need external solution) |

### 6. Application Architecture: 3-Tier with PostgreSQL

**Decision:** Flask API + Nginx + PostgreSQL

**Rationale:**
- Demonstrates realistic stateful workload
- Shows PVC usage for persistence
- Proper database with SQL queries

**Trade-offs Accepted:**
| Pro | Con |
|-----|-----|
| Real database persistence | More complex than Redis |
| SQL demonstrates ORM patterns | Single replica (not HA) |
| Production-like setup | Backup not implemented |

---

## Assumptions Made

| # | Assumption | Impact |
|---|------------|--------|
| 1 | **Single environment** | No dev/staging/prod separation; all in one namespace |
| 2 | **Public API server** | AKS API endpoint is internet-accessible |
| 3 | **Plain HTTP** | No TLS/HTTPS certificates configured |
| 4 | **Kubernetes Secrets** | Database credentials stored as base64 in K8s (not encrypted at rest) |
| 5 | **Single region** | No geo-redundancy or multi-zone node pools |
| 6 | **DockerHub public** | Container images are publicly accessible |
| 7 | **No resource quotas** | Namespace has no CPU/memory limits enforced |
| 8 | **Manual initial setup** | Terraform run manually, not in pipeline |

---

## Production Improvements

### 🔒 Security Enhancements

| Improvement | Current State | Production Solution |
|-------------|---------------|---------------------|
| **Private AKS Cluster** | Public API endpoint | Enable private cluster; API only via private endpoint |
| **Azure Front Door + WAF** | Direct LoadBalancer | Front Door for global load balancing + Web Application Firewall |
| **Bastion Host** | kubectl from anywhere | Azure Bastion for secure cluster access |
| **External Secrets** | K8s Secrets (base64) | Azure Key Vault + External Secrets Operator or CSI driver |
| **Network Policies** | None | Calico/Cilium policies for pod-to-pod microsegmentation |
| **Pod Security Standards** | None | Enforce restricted PSS; no privileged containers |
| **Private Container Registry** | DockerHub public | ACR with private endpoint + vulnerability scanning |
| **Azure AD Integration** | None | RBAC via Azure AD groups; MFA for cluster access |
| **Audit Logging** | None | Azure Monitor + Log Analytics for API server audit logs |

### 🌐 Networking Improvements

| Improvement | Current State | Production Solution |
|-------------|---------------|---------------------|
| **Application Gateway Ingress** | LoadBalancer per service | Single AGIC with WAF for all ingress |
| **Azure Firewall** | NAT Gateway only | Azure Firewall for egress filtering + FQDN rules |
| **Private DNS Zones** | Azure DNS labels | Private DNS for internal service discovery |
| **Better NSG Rules** | Broad HTTP/HTTPS allow | Application-specific rules with service tags |
| **DDoS Protection** | Basic only | Azure DDoS Protection Standard |
| **TLS Everywhere** | HTTP only | cert-manager + Let's Encrypt; mTLS with service mesh |

### 📈 High Availability & Scalability

| Improvement | Current State | Production Solution |
|-------------|---------------|---------------------|
| **Multi-zone Node Pools** | Single zone | Nodes across 3 availability zones |
| **Cluster Autoscaler** | Fixed 2 nodes | Auto-scale 2-10 nodes based on load |
| **Horizontal Pod Autoscaler** | Fixed replicas | HPA based on CPU/memory/custom metrics |
| **PostgreSQL HA** | Single pod | Azure Database for PostgreSQL (Flexible Server) with HA |
| **Multi-region** | Single region | Geo-distributed clusters with Azure Traffic Manager |
| **Pod Disruption Budgets** | None | PDBs to ensure availability during updates |

### 🔧 Operations & Observability

| Improvement | Current State | Production Solution |
|-------------|---------------|---------------------|
| **Monitoring Stack** | None | Prometheus + Grafana or Azure Monitor Container Insights |
| **Log Aggregation** | kubectl logs only | Fluentd/Fluent Bit → Azure Log Analytics or ELK |
| **Alerting** | None | Azure Monitor alerts + PagerDuty/OpsGenie integration |
| **Tracing** | None | OpenTelemetry + Jaeger or Azure Application Insights |
| **Backup & DR** | None | Velero for cluster backup; geo-replicated storage |
| **GitOps for Infra** | Manual terraform | Terraform in GitHub Actions with state in Azure Storage |

### 💰 Cost Optimization

| Improvement | Current State | Production Solution |
|-------------|---------------|---------------------|
| **Spot Instances** | On-demand only | Spot node pool for non-critical workloads (90% savings) |
| **Reserved Instances** | Pay-as-you-go | 1-3 year reservations for baseline (up to 72% off) |
| **Right-sizing** | Standard_D2s_v6 | Analyze metrics and right-size VMs |
| **Cluster Stop** | Always running | Stop dev/test clusters outside business hours |
| **Cost Alerts** | None | Azure Cost Management budgets and alerts |

---

## POC vs Production Comparison

| Aspect | POC (Current) | Production Recommendation |
|--------|---------------|---------------------------|
| **API Server** | Public endpoint | Private endpoint + Bastion |
| **Container Registry** | DockerHub (public) | ACR with private endpoint |
| **Secrets** | K8s Secrets | Azure Key Vault + CSI driver |
| **TLS/SSL** | None (HTTP) | cert-manager + Let's Encrypt |
| **WAF** | None | Azure Front Door + WAF |
| **Ingress** | LoadBalancer per service | Application Gateway (AGIC) |
| **Egress Firewall** | NAT Gateway | Azure Firewall with FQDN filtering |
| **Database** | PostgreSQL pod | Azure Database for PostgreSQL |
| **Node Pools** | 1 pool, 2 nodes, 1 zone | 2+ pools, 3-10 nodes, 3 zones |
| **Monitoring** | kubectl | Prometheus/Grafana + Azure Monitor |
| **Backup** | None | Velero + geo-replicated storage |
| **CI/CD Secrets** | GitHub Secrets | Azure Key Vault + OIDC |
| **Network Policies** | None | Calico/Cilium micro-segmentation |

---

## Estimated Costs

### POC (Current)
| Resource | Monthly Cost |
|----------|-------------|
| AKS Control Plane | Free |
| 2x Standard_D2s_v6 | ~$120 |
| NAT Gateway | ~$35 |
| Public IPs (2) | ~$6 |
| Storage (1Gi PVC) | ~$1 |
| **Total** | **~$162/month** |

### Production (Estimated)
| Resource | Monthly Cost |
|----------|-------------|
| AKS Control Plane | Free |
| 6x Standard_D4s_v5 (with RI) | ~$450 |
| Azure Firewall | ~$900 |
| Azure Front Door Premium | ~$350 |
| Azure Database PostgreSQL | ~$200 |
| ACR Premium | ~$50 |
| Azure Key Vault | ~$5 |
| Log Analytics (100GB) | ~$230 |
| **Total** | **~$2,185/month** |

---

## File Structure

```
devops_task/
├── terraform/
│   ├── main.tf              # Root module, resource group, module calls
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   ├── providers.tf         # Azure, Kubernetes, Helm providers
│   ├── versions.tf          # Provider version constraints
│   ├── terraform.tfvars     # Variable values
│   └── modules/
│       ├── network/         # VNet, subnets, NAT Gateway, NSGs
│       ├── aks/             # AKS cluster, managed identity
│       ├── acr/             # Container registry (commented out)
│       └── argocd/          # ArgoCD Helm installation + Application CRD
├── app/
│   ├── frontend/            # Nginx with custom config (Dockerfile)
│   └── backend/             # Flask API application (Dockerfile)
├── helm/
│   └── demo-app/            # 3-tier application Helm chart
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/       # Deployments, Services, Secrets, PVC
├── .github/
│   └── workflows/
│       └── ci-cd.yaml       # GitHub Actions pipeline with paths-filter
├── docs/
│   ├── architecture.drawio  # Draw.io architecture diagram
│   └── task1-architecture.drawio  # Detailed Task 1 diagram
├── SOLUTION.md              # This document
└── README.md                # Deployment instructions
```

---

## References

- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure AKS Best Practices](https://learn.microsoft.com/en-us/azure/aks/best-practices)
- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Documentation](https://helm.sh/docs/)
- [Azure Front Door + WAF](https://learn.microsoft.com/en-us/azure/frontdoor/)
