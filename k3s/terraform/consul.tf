#------------------------------------------------------------------------------------------------------------------
# Consul
#------------------------------------------------------------------------------------------------------------------
resource "kubernetes_namespace" "consul" {
  metadata {
    name = "consul"
  }
}

resource "helm_release" "consul" {
  name       = "consul"
  namespace  = kubernetes_namespace.consul.metadata[0].name
  chart      = "consul"
  repository = "https://helm.releases.hashicorp.com"

  set {
    name  = "global.datacenter"
    value = "blizzard"
  }

  set {
    name  = "global.name"
    value = "consul"
  }

  set {
    name  = "global.image"
    value = "hashicorp/consul:1.9.3"
  }

  set {
    name  = "global.imageEnvoy"
    value = "jsiebens/envoy-arm64:1.13.3"
  }

  set {
    name  = "connectInject.enabled"
    value = true
  }

  set {
    name  = "server.replicas"
    value = 3
  }

  set {
    name  = "server.bootstrapExpect"
    value = 3
  }

  set {
    name  = "server.storage"
    value = "1Gi"
  }

  set {
    name  = "server.storageClass"
    value = kubernetes_storage_class.nfs_client_provisioner.metadata[0].name
  }

  set {
    name  = "server.exposeGossipAndRPCPorts"
    value = true
  }

  set {
    name  = "server.ports.serflan.port"
    value = "9301"
  }

  set {
    name  = "server.metrics.enabled"
    value = true
  }

  set {
    name  = "server.metrics.enableAgentMetrics"
    value = true
  }

  set {
    name  = "client.exposeGossipPorts"
    value = true
  }

  set {
    name  = "ui.metrics.enabled"
    value = true
  }

  set {
    name  = "ui.metrics.baseURL"
    value = "http://prometheus-operated.monitoring:9090"
  }
}

resource "kubernetes_ingress" "consul" {
  depends_on = [helm_release.consul]

  metadata {
    name      = "consul"
    namespace = kubernetes_namespace.consul.metadata[0].name
  }

  spec {
    rule {
      host = "consul.coldbrew.labs"

      http {
        path {
          backend {
            service_name = "consul-ui"
            service_port = 80
          }

          path = "/"
        }
      }
    }
  }
}
