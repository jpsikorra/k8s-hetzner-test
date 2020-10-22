variable "controller_nodes" {
  description = "The number of controller nodes to provision."
  type = number
  default = 3
}

variable "controller_node_type" {
  description = "The type of the controller nodes."
  type = string
  default = "cpx11"
}

variable "worker_node_type" {
  description = "The type of the controller nodes."
  type = string
  default = "cx11"
}

variable "worker_nodes" {
  description = "The number of worker nodes to provision."
  type = number
  default = 3
}

variable "location" {
  description = "Hetzner datacenter location"
  type = string
  default = "fsn1"
}

variable "node_admin_ssh_public_key" {
  description = "Location of the SSH public key used to connect to the nodes."
  type = string
}
