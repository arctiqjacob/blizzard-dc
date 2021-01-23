# HashiCorp Vault Deployment

## Installing Vault
```bash
$ helm install vault hashicorp/vault -n vault --values values.yaml
```

## Configuring Vault Policies
```bash
# apply admin policy
$ vault policy write admin policies/admin.hcl
Success! Uploaded policy: admin
```

## Configuring Vault Authentication
```bash
# enable userpass authentication method
$ vault auth enable userpass
Success! Enabled userpass auth method at: userpass/

# create a user
$ vault write auth/userpass/users/jacobm \
  password=foo policies=admin
Success! Data written to: auth/userpass/users/jacobm
```

## Configuring Vault Groups
```bash
# create the admin group
$ vault write identity/group name="admins" policies="admin"
Key     Value
---     -----
id      e9be187a-fc8f-3992-27eb-eefe8523a072
name    admins
```