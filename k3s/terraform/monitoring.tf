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

  set {
    name  = "kube-state-metrics.image.repository"
    value = "k8s.gcr.io/kube-state-metrics-arm64"
  }

  set {
    name  = "kube-state-metrics.image.tag"
    value = "v1.9.5"
  }
}

resource "kubernetes_ingress" "monitoring" {
  depends_on = [helm_release.montoring]

  metadata {
    name      = "monitoring"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    rule {
      host = "grafana.coldbrew.labs"

      http {
        path {
          backend {
            service_name = "prometheus-grafana"
            service_port = 80
          }

          path = "/"
        }
      }
    }
  }
}