# Deploy Media Stack

```bash
$ kubectl apply -f media/namespace.yaml 
namespace/media created

$ kubectl apply -f media/deluge.yaml 
deployment.apps/deluge created
persistentvolumeclaim/deluge-config-pv-claim created
service/deluge-ui created
ingress.networking.k8s.io/deluge created

$ kubectl apply -f media/jackett.yaml 
deployment.apps/jackett created
persistentvolumeclaim/jackett-config-pv-claim created
service/jackett-ui created
ingress.networking.k8s.io/jackett created

$ kubectl apply -f media/sonarr.yaml 
deployment.apps/sonarr created
persistentvolumeclaim/sonarr-config-pv-claim created
service/sonarr-ui created
ingress.networking.k8s.io/sonarr created

$ kubectl apply -f media/radarr.yaml 
deployment.apps/radarr created
persistentvolumeclaim/radarr-config-pv-claim created
service/radarr-ui created
ingress.networking.k8s.io/radarr created

$  kubectl get pods -n media
NAME                       READY   STATUS    RESTARTS   AGE
deluge-66b9589574-7vz5b    1/1     Running   0          28m
jackett-84cd66bf94-lbhrp   1/1     Running   0          8m33s
sonarr-7f79f4858c-hbw5s    1/1     Running   0          4m54s
radarr-b8cf46cc5-8srgn     1/1     Running   0          4m9s

$ kubectl get ingress -n media
NAME      CLASS    HOSTS                   ADDRESS        PORTS   AGE
deluge    <none>   deluge.coldbrew.labs    192.168.1.98   80      24m
jackett   <none>   jackett.coldbrew.labs   192.168.1.98   80      4m30s
sonarr    <none>   sonarr.coldbrew.labs    192.168.1.98   80      51s
radarr    <none>   radarr.coldbrew.labs    192.168.1.98   80      6s

$ kubectl get pvc -n media
NAME                      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS       AGE
deluge-config-pv-claim    Bound    pvc-948f1fd9-980a-402e-b26a-6979057ce4db   500Mi      RWO            coldbrew-storage   28m
jackett-config-pv-claim   Bound    pvc-88fb04d1-eb53-4517-a908-97c8ba0b081e   500Mi      RWO            coldbrew-storage   9m22s
sonarr-config-pv-claim    Bound    pvc-707ea315-6037-4317-9f0b-a3ff2e5900a7   500Mi      RWO            coldbrew-storage   5m43s
radarr-config-pv-claim    Bound    pvc-4071fea8-9b56-455d-8422-4b6e9bd110e0   500Mi      RWO            coldbrew-storage   4m58s
```