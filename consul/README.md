# Consul
The following steps are used to deploy Consul server.

## Deploying Vault
Update the `inventory` file, as well as the `group_vars` file and then run the following commands.
```bash
# install Ansible roles
$ ansible-galaxy install -r requirements.yml

# deploy Consul
$ ansible-playbook -i inventory site.yml -u centos
```