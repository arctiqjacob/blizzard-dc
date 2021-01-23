```bash
$ kubectl apply -f storage.yaml
namespace/storage created
serviceaccount/nfs-client-provisioner created
clusterrole.rbac.authorization.k8s.io/nfs-client-provisioner-runner created
clusterrolebinding.rbac.authorization.k8s.io/run-nfs-client-provisioner created
role.rbac.authorization.k8s.io/leader-locking-nfs-client-provisioner created
rolebinding.rbac.authorization.k8s.io/leader-locking-nfs-client-provisioner created
deployment.apps/nfs-client-provisioner created
storageclass.storage.k8s.io/coldbrew-storage created

$kubectl get storageclass
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  25m
coldbrew-storage       coldbrew.labs/nfs       Delete          Immediate              false                  4m8s

$ kubectl get pods  
NAME                                      READY   STATUS    RESTARTS   AGE
nfs-client-provisioner-6c4bc75f66-np8sm   1/1     Running   0          2m41s

$ kubectl patch storageclass coldbrew-storage  \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
storageclass.storage.k8s.io/coldbrew-storage patched

$ kubectl patch storageclass local-path \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'     
storageclass.storage.k8s.io/local-path patched

$ kubectl get storageclass   
NAME                         PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
coldbrew-storage (default)   coldbrew.labs/nfs       Delete          Immediate              false                  5m28s
local-path                   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  26m
```