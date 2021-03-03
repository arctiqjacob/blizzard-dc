provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "raspberrypi_k3s"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "raspberrypi_k3s"
  }
}