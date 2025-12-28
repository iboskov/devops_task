# DevOps POC - Azure AKS with GitOps

A proof-of-concept for a cloud-native Kubernetes deployment platform using Azure AKS, Terraform, ArgoCD, and GitHub Actions.

## Architecture

![Architecture Diagram](docs/architecture.png)

**Components:**
- **Azure AKS** - Managed Kubernetes cluster
- **DockerHub** - Container registry (ACR support available)
- **ArgoCD** - GitOps continuous delivery
- **GitHub Actions** - CI pipeline with selective builds
- **Helm** - Application packaging

**Application Stack:**
- **Frontend** - Nginx reverse proxy serving static HTML/JS
- **Backend** - Flask REST API with SQLAlchemy
- **Database** - PostgreSQL for persistent storage

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and authenticated
- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/) >= 3.0
- Azure subscription with Contributor access
- Terraform service principal with Contributor and UAA access

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/iboskov/devops_task.git
cd devops_task
```

### 2. Configure Variables

Edit `terraform/terraform.tfvars`:

```hcl
subscription_id     = "SUBSCRIPTION_ID"
location            = "australiacentral"
resource_group_name = "demo-rg"
cluster_name        = "demo-aks"
acr_name            = "youruniquename"  # If you are using ACR this must be globally unique
node_count          = 2
vm_size             = "Standard_D2s_v3"
git_repo_url        = "https://github.com/yourusername/devops_task.git"
```

### 3. Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply (creates all resources)
terraform apply
```

**Note:** If you encounter RBAC permission errors for role assignments, you may need to run manually:

```bash
AKS_IDENTITY=$(az aks show -n demo-aks -g demo-rg --query identity.principalId -o tsv)

# Assign Network Contributor (for LoadBalancer creation)
az role assignment create \
  --assignee $AKS_IDENTITY \
  --role "Network Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/demo-rg/providers/Microsoft.Network/virtualNetworks/demo-aks-vnet

# If you are still having issues you can attach ACR to AKS manually
az aks update -n demo-aks -g demo-rg --attach-acr <acr-name>
```

### 4. Configure kubectl

```bash
az aks get-credentials --resource-group demo-rg --name demo-aks

# Verify that you can access the nodes
kubectl get nodes
```

### 5. Configure and access ArgoCD

```bash
# After terraform apply has been executed you can run
kubectl apply -f ./argocd/application.yaml

# Port forward to ArgoCD - in production this would be through ingress
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Open http://localhost:8080 and login with:
- **Username:** admin
- **Password:** (from command above)

### 6. Verify Application

The demo-app should automatically sync via ArgoCD. Check status:

```bash
kubectl get pods -n demo-app
kubectl get svc -n demo-app
```

You should see 3 pods running:
- `demo-app-frontend-*` - Nginx reverse proxy
- `demo-app-backend-*` - Flask API
- `demo-app-postgres-*` - PostgreSQL database

Access the frontend:
```bash
kubectl port-forward svc/demo-app-frontend -n demo-app 8081:80
# Open http://localhost:8081
```

The frontend provides a simple UI to interact with the backend API for CRUD operations on items stored in PostgreSQL.

## Local Development

You can run the application locally using Docker Compose, be careful of port conflicts if you are testing argocd as well:

```bash
cd app
docker-compose up --build
# Frontend: http://localhost:8080
# Backend API: http://localhost:5000
```

## Helm Chart

The application is packaged as a Helm chart in `helm/demo-app/`:

```
helm/demo-app/
├── Chart.yaml           # Chart metadata
├── values.yaml          # Default configuration values
└── templates/
    ├── frontend-deployment.yaml
    ├── frontend-service.yaml
    ├── backend-deployment.yaml
    ├── backend-service.yaml
    ├── postgres-deployment.yaml
    ├── postgres-service.yaml
    ├── postgres-pvc.yaml
    └── postgres-secret.yaml
```

### Key Values

| Value | Description | Default |
|-------|-------------|---------|
| `frontend.image.repository` | Frontend image | `demo_frontend` |
| `frontend.replicaCount` | Frontend replicas | `2` |
| `backend.image.repository` | Backend image | `demo_backend` |
| `backend.replicaCount` | Backend replicas | `2` |
| `postgres.storage` | Database storage size | `1Gi` |

### Manual Deployment

```bash
# Lint the chart
helm lint helm/demo-app

# Dry-run install
helm install demo-app helm/demo-app --namespace demo-app --create-namespace --dry-run

# Install
helm install demo-app helm/demo-app --namespace demo-app --create-namespace

# Upgrade
helm upgrade demo-app helm/demo-app --namespace demo-app
```

**Note:** In production, ArgoCD manages Helm deployments automatically via GitOps.

## CI/CD Pipeline

### GitHub Actions Workflow

The pipeline (`.github/workflows/ci-cd.yaml`) triggers on push to `main` and builds only changed components using `dorny/paths-filter`:

1. **Detect Changes** - Identifies which components (frontend/backend) changed
2. **Build Frontend** - Only if `app/frontend/**` changed
3. **Build Backend** - Only if `app/backend/**` changed
4. **Update Helm** - Updates image tags in `values.yaml`
5. **ArgoCD Sync** - Automatically detects changes and deploys

### Required GitHub Secrets

Configure these in your repository settings:

| Secret | Description |
|--------|-------------|
| `DOCKERHUB_USERNAME` | Your DockerHub username |
| `DOCKERHUB_TOKEN` | DockerHub access token|

<!-- ACR secrets (if using Azure Container Registry instead):
| `AZURE_CREDENTIALS` | Service principal JSON for Azure login |
| `ACR_LOGIN_SERVER` | ACR URL (e.g., `youracr.azurecr.io`) |
| `ACR_USERNAME` | ACR admin username |
| `ACR_PASSWORD` | ACR admin password |
-->

### Triggering a Deployment

```bash
# Make a change to the app
git add .
git commit -m "Update application"
git push origin main
```

GitHub Actions will build and push the image, ArgoCD will detect the Helm values change and deploy automatically.

## Project Structure

```
.
├── app/                 # Application source code
│   ├── frontend/        # Nginx + static files
│   │   ├── Dockerfile
│   │   ├── nginx.conf
│   │   └── index.html
│   ├── backend/         # Flask API
│   │   ├── Dockerfile
│   │   ├── app.py
│   │   └── requirements.txt
│   └── docker-compose.yaml  # Local development
├── terraform/           # Infrastructure as Code
│   ├── modules/
│   │   ├── network/     # VNet, subnets, NAT, NSGs
│   │   ├── aks/         # Kubernetes cluster
│   │   ├── acr/         # Container registry
│   │   └── argocd/      # ArgoCD installation
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── helm/
│   └── demo-app/        # Application Helm chart
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── backend-deployment.yaml
│           ├── backend-service.yaml
│           ├── frontend-deployment.yaml
│           ├── frontend-service.yaml
│           ├── postgres-deployment.yaml
│           ├── postgres-pvc.yaml
│           ├── postgres-secret.yaml
│           └── postgres-service.yaml
├── .github/
│   └── workflows/
│       └── ci-cd.yaml   # GitHub Actions pipeline
├── docs/
│   └── architecture.png
├── SOLUTION.md          # Design decisions
└── README.md            # This file
```

## Cleanup

Remove all resources:

```bash
cd terraform
terraform destroy
```

## Troubleshooting

### Common Issues

**1. "No such host" error for kubectl**
```bash
# Refresh credentials
az aks get-credentials --resource-group demo-rg --name demo-aks --overwrite-existing
```

**2. LoadBalancer stuck in Pending**
- Check AKS identity has Network Contributor role on VNet
- Check NSG rules allow traffic

**3. ArgoCD sync failed**
- Verify git repository URL is correct and accessible
- Check ArgoCD logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server`

**4. ACR pull errors**
- Ensure AKS has AcrPull role or is attached: `az aks update -n demo-aks -g demo-rg --attach-acr <acr-name>`

**5. Terraform RBAC errors (403)**
- Your Azure account needs Owner or User Access Administrator role
- Alternatively, create role assignments manually with Azure CLI

## Future Improvements

- [ ] Add HTTPS with cert-manager
- [ ] Implement Ingress controller
- [ ] Add monitoring (Prometheus/Grafana)
- [ ] Enable Azure AD authentication
- [ ] Add network policies
- [ ] Implement secrets management with Azure Key Vault
- [ ] Multi-environment support (dev/staging/prod)

