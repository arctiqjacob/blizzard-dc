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