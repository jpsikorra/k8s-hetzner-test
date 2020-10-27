# Run Kubernetes in the Hetzner Cloud (WIP)
Creates a six node kubernetes cluster in a private network in the Hetzner cloud.

Remember, some costs will occur when using the Hetzner Cloud.

## Installation

### Env
- `export HCLOUD_TOKEN=your-hetzner-api-token`
- `export TF_VAR_node_admin_ssh_public_key=path-to-your-ssh-pub-key`
- `export PRIV_KEY_PATH=path-to-your-ssh-priv-key`

### Provisioning
Go into the `provisioning` dir.
- `terraform init`
- `terraform apply`

### Installing
Go into the `configuration` dir.
- `ansible-playbook -i hosts kubernetes.yml -f 6 --private-key=$PRIV_KEY_PATH`

## Testing and playing around
SSH to the first controller (address in file `configuration/hosts`) and run
- `kubectl --kubeconfig /etc/kubernetes/admin.conf get nodes`
which should display your ready nodes.

## All good things must come to an end
If you want to destroy the cluster just run `terraform destroy` in the `provisioning` dir.
