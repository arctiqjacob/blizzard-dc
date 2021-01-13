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

$ kubectl apply -f - <<EOF
kind: Ingress
apiVersion: networking.k8s.io/v1
metadata:
  name: prometheus-grafana
  namespace: monitoring
spec:
  rules:
    - host: "grafana.10.88.111.26.xip.io"
      http:
        paths:
          - path: /
            pathType: Exact
            backend:
              service:
                name: prometheus-grafana
                port:
                  number: 80
EOF
```
