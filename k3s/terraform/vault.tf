#------------------------------------------------------------------------------------------------------------------
# Vault
#------------------------------------------------------------------------------------------------------------------
resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

resource "helm_release" "vault" {
  depends_on = [helm_release.consul]

  name       = "vault"
  namespace  = kubernetes_namespace.vault.metadata[0].name
  chart      = "vault"
  repository = "https://helm.releases.hashicorp.com"

  set {
    name  = "injector.enabled"
    value = true
  }

  set {
    name  = "server.ha.enabled"
    value = true
  }

  set {
    name  = "server.ha.replicas"
    value = 2
  }

  set {
    name  = "ui.enabled"
    value = true
  }

  set {
    name  = "server.ha.config"
    value = <<EOF
ui = true
listener "tcp" {
  tls_disable = 1
  address = "[::]:8200"
  cluster_address = "[::]:8201"
}
storage "consul" {
  path = "vault"
  address = "HOST_IP:8500"
}
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}
EOF
  }
}

resource "kubernetes_ingress" "vault" {
  depends_on = [helm_release.vault]

  metadata {
    name      = "vault"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  spec {
    rule {
      host = "vault.coldbrew.labs"

      http {
        path {
          backend {
            service_name = "vault-ui"
            service_port = 8200
          }

          path = "/"
        }
      }
    }
  }
}