variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "australiacentral"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "demo-rg"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "demo-aks"
}

variable "node_count" {
  description = "Number of nodes"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "VM size for nodes"
  type        = string
  default     = "Standard_D2s_v6"
}
