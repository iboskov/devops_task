# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Network Module
module "network" {
  source = "./modules/network"

  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# AKS Module
module "aks" {
  source = "./modules/aks"

  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  node_count          = var.node_count
  vm_size             = var.vm_size
  subnet_id           = module.network.private_subnet_id
  vnet_id             = module.network.vnet_id

  depends_on = [module.network]
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = module.aks.cluster_name
  resource_group_name = azurerm_resource_group.main.name
}

# ACR Module
module "acr" {
  source = "./modules/acr"

  name                    = "${var.acr_name}acr"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  aks_kubelet_identity_id = module.aks.kubelet_identity_object_id

  depends_on = [module.aks]
}

# ArgoCD Module
module "argocd" {
  source = "./modules/argocd"

  git_repo_url = var.git_repo_url

  depends_on = [module.aks]
}
