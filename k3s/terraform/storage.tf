 #------------------------------------------------------------------------------------------------------------------
# NFS Storage
#------------------------------------------------------------------------------------------------------------------
resource "kubernetes_namespace" "nfs_client_provisioner" {
  metadata {
    name = "storage"
  }
}

resource "kubernetes_service_account" "nfs_client_provisioner" {
  metadata {
    name      = "nfs-client-provisioner"
    namespace = kubernetes_namespace.nfs_client_provisioner.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "nfs_client_provisioner" {
  metadata {
    name = "nfs-client-provisioner-runner"
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["get", "list", "watch", "create", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims"]
    verbs      = ["get", "list", "watch", "update"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "update", "patch"]
  }
}

resource "kubernetes_cluster_role_binding" "nfs_client_provisioner" {
  metadata {
    name = "run-nfs-client-provisioner"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "nfs-client-provisioner-runner"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "nfs-client-provisioner"
    namespace = "storage"
  }
}

resource "kubernetes_role" "nfs_client_provisioner" {
  metadata {
    name      = "leader-locking-nfs-client-provisioner"
    namespace = kubernetes_namespace.nfs_client_provisioner.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["endpoints"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }
}

resource "kubernetes_role_binding" "nfs_client_provisioner" {
  metadata {
    name      = "leader-locking-nfs-client-provisioner"
    namespace = kubernetes_namespace.nfs_client_provisioner.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "leader-locking-nfs-client-provisioner"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "nfs-client-provisioner"
    namespace = "storage"
  }
}

resource "kubernetes_deployment" "nfs_client_provisioner" {
  metadata {
    name      = "nfs-client-provisioner"
    namespace = kubernetes_namespace.nfs_client_provisioner.metadata[0].name

    labels = {
      app = "nfs-client-provisioner"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nfs-client-provisioner"
      }
    }

    template {
      metadata {
        labels = {
          app = "nfs-client-provisioner"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.nfs_client_provisioner.metadata[0].name

        container {
          image = "quay.io/external_storage/nfs-client-provisioner-arm:latest"
          name  = "nfs-client-provisioner"

          env {
            name  = "PROVISIONER_NAME"
            value = "coldbrew.labs/nfs"
          }

          env {
            name  = "NFS_SERVER"
            value = "192.168.1.144"
          }

          env {
            name  = "NFS_PATH"
            value = "/volume1/kubernetes"
          }

          volume_mount {
            mount_path = "/persistentvolumes"
            name       = "nfs-client-root"
          }
        }

        volume {
          name = "nfs-client-root"
          nfs {
            path   = "/volume1/kubernetes"
            server = "192.168.1.144"
          }
        }
      }
    }
  }
}

resource "kubernetes_storage_class" "nfs_client_provisioner" {
  depends_on = [kubernetes_deployment.nfs_client_provisioner]

  metadata {
    name = "coldbrew-storage"
  }

  storage_provisioner = "coldbrew.labs/nfs"

  parameters = {
    onDelete        = "delete"
    archiveOnDelete = "false"
  }
}