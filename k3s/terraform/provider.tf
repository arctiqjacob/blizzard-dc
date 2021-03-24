provider "kubernetes" {
  config_path    = "~/Desktop/kubeconfig"
  config_context = "default"
}

provider "helm" {
  kubernetes {
    config_path    = "~/Desktop/kubeconfig"
    config_context = "default"
  }
}