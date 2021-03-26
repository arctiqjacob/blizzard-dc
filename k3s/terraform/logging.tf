#------------------------------------------------------------------------------------------------------------------
# Logging
#------------------------------------------------------------------------------------------------------------------
resource "kubernetes_namespace" "logging" {
  depends_on = [kubernetes_storage_class.nfs_client_provisioner]
  metadata {
    name = "logging"
  }
}

resource "helm_release" "loki" {
  name       = "loki"
  namespace  = kubernetes_namespace.logging.metadata[0].name
  chart      = "loki"
  repository = "https://grafana.github.io/helm-charts"
}

resource "helm_release" "promtail" {
  name       = "promtail"
  namespace  = kubernetes_namespace.logging.metadata[0].name
  chart      = "promtail"
  repository = "https://grafana.github.io/helm-charts"

  set {
    name  = "config.lokiAddress"
    value = "http://loki.logging:3100/loki/api/v1/push"
  }
}