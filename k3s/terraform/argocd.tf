# #------------------------------------------------------------------------------------------------------------------
# # argocd
# #------------------------------------------------------------------------------------------------------------------
# resource "kubernetes_namespace" "argocd" {
#   metadata {
#     name = "argocd"
#   }
# }

# resource "helm_release" "argocd" {
#   name       = "argocd"
#   namespace  = kubernetes_namespace.argocd.metadata[0].name
#   chart      = "argo-cd"
#   repository = "https://argoproj.github.io/argo-helm"

#   values = [
#     templatefile("values/argocd.tmpl", {})
#   ]
# }