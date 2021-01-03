```bash
$ helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --values monitoring/values.yml
NAME: prometheus
LAST DEPLOYED: Sun Jan  3 17:25:30 2021
NAMESPACE: monitoring
STATUS: deployed
REVISION: 1
...

$ kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
prom-operator

$ kubectl port-forward svc/prometheus-grafana 8080:80 -n monitoring
Forwarding from 127.0.0.1:8080 -> 3000
Forwarding from [::1]:8080 -> 3000
...
```
