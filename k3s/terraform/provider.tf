provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "default"
}

provider "kubernetes-alpha" {
  config_path    = "~/.kube/config"
  config_context = "default"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "default"
  }
}