```bash
$ helm repo update
...
Update Complete. ⎈Happy Helming!⎈

$ helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --values monitoring/values.yml
NAME: prometheus
LAST DEPLOYED: Sun Jan  3 17:25:30 2021
NAMESPACE: monitoring
STATUS: deployed
REVISION: 1
...

$ kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
prom-operator

$ kubectl apply -f ingress.yaml
```
