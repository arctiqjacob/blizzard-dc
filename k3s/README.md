# Raspberry Pi K3s Cluster

## HashiCorp Vault

### Enabling the Userpass Authentication Method
```bash
# Enable the Userpass auth method
$ vault auth enable userpass
Success! Enabled userpass auth method at: userpass/

$ vault write auth/userpass/users/jacobm \
  password=blizzard policies=admins
Success! Data written to: auth/userpass/users/jacobm
```

### Enabling the Kubernetes Authentication Method
```bash
$ kubectl create serviceaccount vault-auth -n vault
serviceaccount/vault-auth created

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

# configure the Kubernetes auth method with the SA JWT, host, and CA cert
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
$ kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: vault-issuer
spec:
  vault:
    path: pki/sign/coldbrew.labs
    server: http://10.43.220.102:8200
    auth:
      kubernetes:
        role: cert-manager
        mountPath: /v1/auth/kubernetes
        secretRef:
          name: cert-manager-vault-token-n22m8 
          key: token
EOF
clusterissuer.cert-manager.io/vault-issuer created

# Verify the cert-manager clusterissuer is ready
$ kubectl get clusterissuer -o wide
NAME           READY   STATUS           AGE
vault-issuer   True    Vault verified   14m
```