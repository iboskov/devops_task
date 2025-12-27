variable "name" {
  description = "Name prefix for network resources"
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

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "public_subnet_prefix" {
  description = "Public subnet address prefix"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_prefix" {
  description = "Private subnet address prefix"
  type        = string
  default     = "10.0.2.0/24"
}
