variable "name" {
  description = "ACR name (alphanumeric only)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "sku" {
  description = "ACR SKU"
  type        = string
  default     = "Basic"
}

variable "aks_kubelet_identity_id" {
  description = "AKS kubelet identity object ID for ACR pull access"
  type        = string
}
