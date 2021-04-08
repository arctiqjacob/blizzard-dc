#------------------------------------------------------------------------------------------------------------------
# Monitoring
#------------------------------------------------------------------------------------------------------------------
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "montoring" {
  name       = "prometheus"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  chart      = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"

  values = [
    templatefile("values/monitoring.tmpl", {})
  ]
}