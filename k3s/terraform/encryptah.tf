#------------------------------------------------------------------------------------------------------------------
# Encryptah
#------------------------------------------------------------------------------------------------------------------
resource "kubernetes_namespace" "encryptah" {
  metadata {
    name = "encryptah"
  }
}

resource "kubernetes_service_account" "encryptah_frontend" {
  metadata {
    name      = "encryptah-frontend"
    namespace = kubernetes_namespace.encryptah.metadata[0].name
  }
}

resource "kubernetes_service_account" "encryptah_backend" {
  metadata {
    name      = "encryptah-backend"
    namespace = kubernetes_namespace.encryptah.metadata[0].name
  }
}

resource "kubernetes_deployment" "encryptah_frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.encryptah.metadata[0].name

    labels = {
      app = "frontend"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app = "frontend"
        }

        annotations = {
          "consul.hashicorp.com/connect-inject" = "true",
          "consul.hashicorp.com/connect-service-upstreams" = "encryptah-backend:5678"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.encryptah_frontend.metadata[0].name

        container {
          image = "jacobmammoliti/encryptah-fe:latest"
          name  = "encryptah-frontend"

          port {
            container_port = "8080"
            name           = "http"
          }

          env {
            name  = "BACKEND_HOSTNAME"
            value = "127.0.0.1"
          }
        }

      }
    }
  }
}

resource "kubernetes_deployment" "encryptah_backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.encryptah.metadata[0].name

    labels = {
      app = "backend"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend"
        }

        annotations = {
          "consul.hashicorp.com/connect-inject" = "true"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.encryptah_backend.metadata[0].name

        container {
          image = "jacobmammoliti/encryptah-be"
          name  = "encryptah-backend"

          port {
            container_port = "5678"
            name           = "http"
          }
        }

      }
    }
  }
}

resource "kubernetes_service" "encryptah_frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.encryptah.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.encryptah_frontend.metadata.0.labels.app
    }

    port {
      port        = kubernetes_deployment.encryptah_frontend.spec[0].template[0].spec[0].container[0].port[0].container_port
      target_port = kubernetes_deployment.encryptah_frontend.spec[0].template[0].spec[0].container[0].port[0].container_port
    }

  }
}

resource "kubernetes_service" "encryptah_backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.encryptah.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.encryptah_backend.metadata.0.labels.app
    }

    port {
      port        = kubernetes_deployment.encryptah_backend.spec[0].template[0].spec[0].container[0].port[0].container_port
      target_port = kubernetes_deployment.encryptah_backend.spec[0].template[0].spec[0].container[0].port[0].container_port
    }

  }
}

resource "kubernetes_ingress" "encryptah" {
  depends_on = [kubernetes_service.encryptah_frontend]

  metadata {
    name      = "encryptah"
    namespace = kubernetes_namespace.encryptah.metadata[0].name
  }

  spec {
    rule {
      host = "encryptah.coldbrew.labs"

      http {
        path {
          backend {
            service_name = "frontend"
            service_port = 8080
          }

          path = "/"
        }
      }
    }
  }
}