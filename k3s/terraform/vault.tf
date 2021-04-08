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

  values = [
    templatefile("values/vault.tmpl", {})
  ]
}