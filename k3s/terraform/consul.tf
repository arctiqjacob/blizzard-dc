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

  values = [
    templatefile("values/consul.tmpl", {})
  ]
}