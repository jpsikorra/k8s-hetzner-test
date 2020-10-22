terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.22.0"
    }
  }
}

provider "hcloud" {
}

resource "hcloud_ssh_key" "node_admin" {
  name = "k8s-node-admin"
  public_key = file(var.node_admin_ssh_public_key)
}

resource "hcloud_network" "main" {
  name = "k8s-main"
  ip_range = "10.240.0.0/24"
}

resource "hcloud_network_subnet" "main" {
  network_id = hcloud_network.main.id
  type = "cloud"
  network_zone = "eu-central"
  ip_range   = "10.240.0.0/25"
}

resource "hcloud_load_balancer" "controller" {
  name = "k8s-controller"
  load_balancer_type = "lb11"
  location = "fsn1"
  algorithm {
    type = "round_robin"
  }
}

resource "hcloud_load_balancer_network" "controller" {
  load_balancer_id = hcloud_load_balancer.controller.id
  subnet_id = hcloud_network_subnet.main.id
  enable_public_interface = false
}

resource "hcloud_server" "controller" {
  count = var.controller_nodes

  name = "k8s-controller-${count.index}"
  server_type = var.controller_node_type
  image = "ubuntu-20.04"
  location = "fsn1"
  ssh_keys = [hcloud_ssh_key.node_admin.id]
  backups = false
}

resource "time_sleep" "controller_boot" {
  depends_on = [hcloud_server.controller]
  create_duration = "30s"
}

resource "hcloud_server_network" "controller" {
  count = var.controller_nodes

  depends_on = [time_sleep.controller_boot]
  server_id = hcloud_server.controller.*.id[count.index]
  network_id = hcloud_network.main.id
}

resource "hcloud_load_balancer_target" "controller" {
  depends_on = [
    hcloud_server_network.controller,
    hcloud_load_balancer_network.controller
  ]

  count = var.controller_nodes

  type = "server"
  load_balancer_id = hcloud_load_balancer.controller.id
  server_id = hcloud_server.controller[count.index].id
  use_private_ip = true
}

resource "hcloud_load_balancer_service" "control_plane_endpoint" {
    load_balancer_id = hcloud_load_balancer.controller.id
    protocol = "tcp"
    listen_port = 6443
    destination_port = 6443
}

resource "hcloud_server" "worker" {
  count = var.worker_nodes

  name = "k8s-worker-${count.index}"
  server_type = var.worker_node_type
  image = "ubuntu-20.04"
  location = "fsn1"
  ssh_keys = [hcloud_ssh_key.node_admin.id]
  backups = false
}

resource "time_sleep" "worker_boot" {
  depends_on = [hcloud_server.worker]
  create_duration = "30s"
}

resource "hcloud_server_network" "worker" {
  count = var.worker_nodes

  depends_on = [time_sleep.worker_boot]
  server_id = hcloud_server.worker.*.id[count.index]
  network_id = hcloud_network.main.id
}

locals {
  controllers = [for i, c in hcloud_server.controller:merge(
    c,
    { private_ip = hcloud_server_network.controller[i].ip }
  )]

  workers = [for i, w in hcloud_server.worker:merge(
    w,
    { private_ip = hcloud_server_network.worker[i].ip }
  )]
}

resource "local_file" "ansible_hosts" {
  content     = templatefile("${path.module}/templates/ansible_hosts", {
    controllers = local.controllers
    workers = local.workers
  })
  filename = "${path.module}/../configuration/hosts"
}

resource "local_file" "ansible_vars" {
  content = templatefile("${path.module}/templates/ansible_vars", {
    controller_lb = hcloud_load_balancer_network.controller
  })
  filename = "${path.module}/../configuration/group_vars/all"
}
