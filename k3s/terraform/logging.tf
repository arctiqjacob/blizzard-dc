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


# resource "helm_release" "elasticsearch" {
#   name       = "elasticsearch"
#   namespace  = kubernetes_namespace.logging.metadata[0].name
#   chart      = "elasticsearch"
#   repository = "https://helm.elastic.co"

#   set {
#     name  = "resources.requests.cpu"
#     value = "750m"
#   }

#   set {
#     name  = "resources.requests.memory"
#     value = "1.5Gi"
#   }

#   set {
#     name  = "resources.limits.cpu"
#     value = "750m"
#   }

#   set {
#     name  = "resources.limits.memory"
#     value = "1.5Gi"
#   }

#   set {
#     name  = "volumeClaimTemplate.resources.requests.storage"
#     value = "10Gi"
#   }
# }

# resource "helm_release" "filebeat" {
#   name       = "filebeat"
#   namespace  = kubernetes_namespace.logging.metadata[0].name
#   chart      = "filebeat"
#   repository = "https://helm.elastic.co"
# }

# resource "helm_release" "kibana" {
#   name       = "kibana"
#   namespace  = kubernetes_namespace.logging.metadata[0].name
#   chart      = "kibana"
#   repository = "https://helm.elastic.co"

#   set {
#     name  = "resources.requests.cpu"
#     value = "500m"
#   }

#   set {
#     name  = "resources.requests.memory"
#     value = "1Gi"
#   }

#   set {
#     name  = "resources.limits.cpu"
#     value = "500m"
#   }

#   set {
#     name  = "resources.limits.memory"
#     value = "1Gi"
#   }
# }