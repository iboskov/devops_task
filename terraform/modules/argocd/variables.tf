variable "namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.51.6"
}

variable "git_repo_url" {
  description = "Git repository URL for ArgoCD to sync from"
  type        = string
}

variable "git_target_revision" {
  description = "Git branch/tag to track"
  type        = string
  default     = "main"
}

variable "app_path" {
  description = "Path to Helm chart in the repository"
  type        = string
  default     = "helm/demo-app"
}

variable "app_namespace" {
  description = "Namespace where the app will be deployed"
  type        = string
  default     = "demo-app"
}
