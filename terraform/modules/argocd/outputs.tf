output "namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.argocd.name
}
