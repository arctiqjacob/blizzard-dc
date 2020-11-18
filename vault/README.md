# Vault
The following steps are used to deploy Consul client agent and Vault server.

## Deploying Vault
Update the `inventory` file, as well as the `group_vars` file and then run the following commands.
```bash
# install Ansible roles
$ ansible-galaxy install -r requirements.yml

# deploy Consul and Vault if ACLs are not enabled
$ ansible-playbook -i inventory site.yml -u centos

# deploy Consul and Vault if ACLs are enabled
$ ansible-playbook -i inventory site.yml -u centos \
  --extra-vars "consul_acl_agent_token=REDACTED consul_vault_acl_token=REDACTED"
```