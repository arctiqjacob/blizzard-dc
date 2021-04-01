# Raspberry Pi K3s Cluster

## HashiCorp Consul

### Configuring the Ingress Gateway for Encryptah
This assumes the Ingress Gateway and Encryptah are already deployed. Can't do this through Terraform's Kubernetes Alpha provider at this time.
```bash
# Create the Service Default
$ kubectl apply -f - <<EOF
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceDefaults
metadata:
  name: encryptah-frontend
spec:
  protocol: 'http'
EOF

# Create the Service Resolver
$ kubectl apply -f - <<EOF
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceResolver
metadata:
  name: encryptah-frontend
spec:
  defaultSubset: v1
  subsets:
    v1:
      filter: 'Service.Meta.version == v1'
      onlyPassing: true
    v2:
      filter: 'Service.Meta.version == v2'
      onlyPassing: true
EOF

# Create the Service Splitter
$ kubectl apply -f - <<EOF
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceSplitter
metadata:
  name: encryptah-frontend
spec:
  splits:
    - weight: 50
      service: encryptah-frontend
      serviceSubset: v1
    - weight: 50
      service: encryptah-frontend
      serviceSubset: v2
EOF

# Create the Ingress Gateway entry
$ kubectl apply -f - <<EOF
apiVersion: consul.hashicorp.com/v1alpha1
kind: IngressGateway
metadata:
  name: ingress-gateway
spec:
  listeners:
    - port: 8080
      protocol: http
      services:
        - name: encryptah-frontend
          hosts: ['encryptah.coldbrew.labs']
EOF
```

## HashiCorp Vault

### Enabling the Userpass Authentication Method
```bash
# Enable the Userpass auth method
$ vault auth enable userpass
Success! Enabled userpass auth method at: userpass/

# Create an admin user
$ vault write auth/userpass/users/jacobm \
  password=blizzard policies=admins
Success! Data written to: auth/userpass/users/jacobm

# A user that authenticates with userpass will get a token with a 24h TTL
$ vault auth tune -default-lease-ttl=24h userpass/
Success! Tuned the auth method at: userpass/
```

### Enabling LDAP Authentication Method
```bash
# Enable the ldap auth method
$ vault auth enable ldap
Success! Enabled ldap auth method at: ldap/

# Apply ldap config
$ vault write auth/ldap/config \
  url="ldap://blizzard-nas.coldbrew.labs" \
  groupdn="cn=groups,dc=blizzard-nas,dc=coldbrew,dc=labs" \
  userdn="dc=blizzard-nas,dc=coldbrew,dc=labs" \
  binddn="uid=root,cn=users,dc=blizzard-nas,dc=coldbrew,dc=labs" \
  bindpass="mysecretpassword"
Success! Data written to: auth/ldap/config

# Attach ldap group administrators to the admins Vault policy
$ vault write auth/ldap/groups/administrators policies=admins
Success! Data written to: auth/ldap/groups/administrators

# A user that authenticates with ldap will get a token with a 4h TTL
$ vault auth tune -default-lease-ttl=4h ldap/
Success! Tuned the auth method at: ldap/
```

### Enabling the Kubernetes Authentication Method
```bash
# Create a dedicated SA to broker the authentication between SAs and Vault
$ kubectl create serviceaccount vault-auth -n vault
serviceaccount/vault-auth created

# Create a ClusterRoleBinding for the above SA
$ kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: vault-auth
  namespace: vault
EOF
clusterrolebinding.rbac.authorization.k8s.io/role-tokenreview-binding created

# Get the secret name for the new SA
$ export VAULT_SA_NAME=$(kubectl get sa vault-auth -n vault -o jsonpath="{.secrets[*]['name']}")

# Get the SA JWT token
$ export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -n vault -o jsonpath="{.data.token}" | base64 --decode; echo)

# Get Kubernetes CA certificate
$ export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -n vault -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)

# Get Kubernetes endpoint
$ export K8S_HOST=https://192.168.1.85:6443

# Enable the Kubernetes auth method
$ vault auth enable kubernetes
Success! Enabled kubernetes auth method at: kubernetes/

# Configure the Kubernetes auth method with the SA JWT, host, and CA cert
$ vault write auth/kubernetes/config token_reviewer_jwt="$SA_JWT_TOKEN" \
  kubernetes_host="$K8S_HOST" kubernetes_ca_cert="$SA_CA_CRT"
Success! Data written to: auth/kubernetes/config
```

### Enabling the PKI Secrets Engine
```bash
# Generate a CA and private key with Consul
$ consul tls ca create -domain=coldbrew.labs -days=365 
==> Saved coldbrew.labs-agent-ca.pem
==> Saved coldbrew.labs-agent-ca-key.pem

# Consolidate CA and private key to single file for Vault
$ cat coldbrew.labs-agent-ca-key.pem >> coldbrew.labs-agent-ca.pem

# Authenticate to Vault
$ vault login -method=userpass username=jacobm
Password (will be hidden): 
...

# Enable the PKI secrets engine
$ vault secrets enable pki
Success! Enabled the pki secrets engine at: pki/

# Write CA and private key to PKI secrets engine
$ vault write pki/config/ca pem_bundle=@coldbrew.labs-agent-ca.pem
Success! Data written to: pki/config/ca

# Create a PKI role
$ vault write pki/roles/coldbrew.labs allowed_domains='coldbrew.labs' \
  allow_subdomains=true max_ttl=168h
Success! Data written to: pki/roles/coldbrew.labs
```

### Creating a Vault Token Role
```bash
# Create a policy named 'orchestrator' allowing the orchestrator to create tokens 
$ vault policy write orchestrator - <<EOF
path "auth/token/create/orchestrator" {
  capabilities = ["sudo", "create", "update"] 
}

path "auth/token/roles/orchestrator" { 
  capabilities = ["read"] 
}
EOF
Success! Uploaded policy: orchestrator

# Create the orchestrator token role that is only allowed to create tokens with 'policy-rw' policy
$ vault write auth/token/roles/orchestrator allowed_policies=policy-rw period=5m
Success! Data written to: auth/token/roles/orchestrator

# Create a token with the orchestrator role
$ vault token create -role=orchestrator
Key                  Value
---                  -----
token                s.Ndd4S9tr4WLDDPaGERP6a3Y9
token_accessor       HiXdO8FgpowdnVc39OEoqGCj
token_duration       5m
token_renewable      true
token_policies       ["default" "policy-rw"]
identity_policies    []
policies             ["default" "policy-rw"]
```

### Kubernetes Application Retriving Secrets from Vault
Deploy a simple NGINX pod that retrives and displays secrets from a KV Secrets Engine.
```bash
# Create a Vault policy for NGINX
$ vault policy write nginx - <<EOF
path "static/data/accounts/admin" {
  capabilities = ["read"] 
}
EOF
Success! Uploaded policy: nginx

# Create a dedicated SA for NGINX deployment
$ kubectl create sa nginx
serviceaccount/nginx created

# Create a Vault role in the Kubernetes Auth for NGINX
$ vault write auth/kubernetes/role/nginx \
  bound_service_account_names=nginx \
  bound_service_account_namespaces=default \
  policies=nginx ttl=30m
Success! Data written to: auth/kubernetes/role/nginx

# Deploy NGINX
$ kubectl create -f manifests/nginx.yaml
serviceaccount/nginx created
configmap/nginx-conf created
deployment.apps/nginx created
service/nginx created

# Verify the pod is running
$ kubectl get pods                                 
NAME                    READY   STATUS    RESTARTS   AGE
nginx-7c8888986-6hmr6   2/2     Running   0          8m8s

# View the logs of the vault-agent container to ensure successful secret retrieval
$ kubectl logs nginx-7c8888986-6hmr6 vault-agent -f
==> Vault agent started! Log data will stream in below:

==> Vault agent configuration:
...

# Port-forward the NGINX service
$ kubectl port-forward svc/nginx 8080:80
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
...

# cURL the service to verify the secrets show successfully
$ curl http://127.0.0.1:8080
<html>
<body>
<p>Some secrets:</p><ul>
<li><pre>username: admin</pre></li>
<li><pre>password: mysecretpassword123</pre></li>
</ul></body>
</html>
```

## cert-manager

### Enabling cert-manager with HashiCorp Vault
```bash
# Create a Vault policy for cert-manager
$ vault policy write cert-manager - <<EOF
path "pki/sign/coldbrew.labs" {
  capabilities = ["create", "update"] 
}
EOF
Success! Uploaded policy: cert-manager

# Create a dedicated SA for cert-manager
$ kubectl create sa cert-manager-vault -n cert-manager
serviceaccount/cert-manager-vault created

# Create a Vault role in the Kubernetes Auth for cert-manager
$ vault write auth/kubernetes/role/cert-manager \
  bound_service_account_names=cert-manager-vault \
  bound_service_account_namespaces=cert-manager \
  policies=cert-manager ttl=24h
Success! Data written to: auth/kubernetes/role/cert-manager

# Get the name of cert-manager SA token secret
$ kubectl get secrets -n cert-manager | grep vault
cert-manager-vault-token-n22m8        kubernetes.io/service-account-token   3      2m14s

# Create the cert-manager ClusterIssuer
$ kubectl create -f manifests/clusterissuer.yaml
clusterissuer.cert-manager.io/vault-issuer created

# Verify the cert-manager clusterissuer is ready
$ kubectl get clusterissuer -o wide
NAME           READY   STATUS           AGE
vault-issuer   True    Vault verified   14m
```

### Create and Sign a Certificate with cert-manager and Vault
```bash
# Create the cert-manager certificate resource 

```