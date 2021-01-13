```bash
# Create a sample application pod
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: httpd
  annotations:
    'consul.hashicorp.com/connect-inject': 'true'
spec:
  containers:
    - name: httpd
      image: httpd
      ports:
        - name: httpd
          containerPort: 8080
          protocol: TCP
EOF
pod/httpd created

# Get the pods IP
$ kubectl get pod httpd -o wide
NAME    READY   STATUS    RESTARTS   AGE   IP           NODE            NOMINATED NODE   READINESS GATES
httpd   1/1     Running   0          12s   10.42.1.39   raspberrypi02   <none>           <none>

# Create the Consul service definition with an HTTP health check
$ echo '{
  "name": "httpd",
  "tags": [
    "httpd"
  ],
  "port": 80,
  "address": "10.42.1.39",
  "check": {
    "name": "HTTP API on port 80",
    "http": "http://10.42.1.39:80",
    "method": "GET",
    "Interval": "10s",
    "Timeout": "5s"
  }
}' > payload.json

# Register the service to Consul
$ curl --request PUT --data @payload.json http://10.88.111.27:8500/v1/agent/service/register

# Query the Consul agent to see the service
$ curl http://10.88.111.27:8500/v1/agent/services | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   300  100   300    0     0  60000      0 --:--:-- --:--:-- --:--:-- 60000
{
  "httpd": {
    "ID": "httpd",
    "Service": "httpd",
    "Tags": [
      "httpd"
    ],
    "Meta": {},
    "Port": 80,
    "Address": "10.42.1.37",
    "TaggedAddresses": {
      "lan_ipv4": {
        "Address": "10.42.1.37",
        "Port": 80
      },
      "wan_ipv4": {
        "Address": "10.42.1.37",
        "Port": 80
      }
    },
    "Weights": {
      "Passing": 1,
      "Warning": 1
    },
    "EnableTagOverride": false,
    "Datacenter": "blizzard"
  }
}

$ curl http://10.88.111.27:8500/v1/health/service/httpd | jq 
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1373  100  1373    0     0  91533      0 --:--:-- --:--:-- --:--:-- 91533
[
  {
    "Node": {
      "ID": "2eb28b16-3a98-eabe-9e70-c921c45a8aaf",
      "Node": "raspberrypi02",
      "Address": "10.42.1.34",
      "Datacenter": "blizzard",
      "TaggedAddresses": {
        "lan": "10.42.1.34",
        "lan_ipv4": "10.42.1.34",
        "wan": "10.42.1.34",
        "wan_ipv4": "10.42.1.34"
      },
      "Meta": {
        "consul-network-segment": "",
        "pod-name": "consul-5p8vm"
      },
      "CreateIndex": 18,
      "ModifyIndex": 19
    },
    "Service": {
      "ID": "httpd",
      "Service": "httpd",
      "Tags": [
        "httpd"
      ],
      "Address": "10.42.1.39",
      "TaggedAddresses": {
        "lan_ipv4": {
          "Address": "10.42.1.39",
          "Port": 80
        },
        "wan_ipv4": {
          "Address": "10.42.1.39",
          "Port": 80
        }
      },
      "Meta": null,
      "Port": 80,
      "Weights": {
        "Passing": 1,
        "Warning": 1
      },
      "EnableTagOverride": false,
      "Proxy": {
        "MeshGateway": {},
        "Expose": {}
      },
      "Connect": {},
      "CreateIndex": 11081,
      "ModifyIndex": 11081
    },
    "Checks": [
      {
        "Node": "raspberrypi02",
        "CheckID": "serfHealth",
        "Name": "Serf Health Status",
        "Status": "passing",
        "Notes": "",
        "Output": "Agent alive and reachable",
        "ServiceID": "",
        "ServiceName": "",
        "ServiceTags": [],
        "Type": "",
        "Definition": {},
        "CreateIndex": 18,
        "ModifyIndex": 18
      },
      {
        "Node": "raspberrypi02",
        "CheckID": "service:httpd",
        "Name": "HTTP API on port 80",
        "Status": "passing",
        "Notes": "",
        "Output": "HTTP GET http://10.42.1.39:80: 200 OK Output: <html><body><h1>It works!</h1></body></html>\n",
        "ServiceID": "httpd",
        "ServiceName": "httpd",
        "ServiceTags": [
          "httpd"
        ],
        "Type": "http",
        "Definition": {},
        "CreateIndex": 11081,
        "ModifyIndex": 11083
      }
    ]
  }
]


# Get the IP of Consul's DNS server
$ kubectl get svc consul-dns -n consul
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)         AGE
consul-dns   ClusterIP   10.43.110.177   <none>        53/TCP,53/UDP   4h57m

# Lookup the service via Consul
$ kubectl exec -it consul-server-0 -n consul -- nslookup httpd.service.blizzard.consul 10.43.110.177  
Server:		10.43.110.177
Address:	10.43.110.177:53

Name:	httpd.service.blizzard.consul
Address: 10.42.1.37

# Delete the pod
$ kubectl delete pod httpd
pod "httpd" deleted

# Verify Consul updated its registry and does not return the record back
$ kubectl exec -it consul-server-0 -n consul -- nslookup httpd.service.blizzard.consul 10.43.110.177
Server:		10.43.110.177
Address:	10.43.110.177:53

** server can't find httpd.service.blizzard.consul: NXDOMAIN

** server can't find httpd.service.blizzard.consul: NXDOMAIN

command terminated with exit code 1

# Deregister the service from Consul
$ curl --request PUT http://10.88.111.27:8500/v1/agent/service/deregister/httpd
```