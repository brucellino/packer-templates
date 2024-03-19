packer {
  required_plugins {
    digitalocean = {
      version = ">= v1.1.0"
      source  = "github.com/digitalocean/digitalocean"
    }
    docker = {
      version = ">= v1.0.8"
      source  = "github.com/hashicorp/docker"
    }
    ansible = {
      version = "~> 1"
      source = "github.com/hashicorp/ansible"
    }
  }
}
variable "consul_version" {
  description = "Version of Consul to install"
  default     = "1.15.0"
  type        = string
}

local "gossip_key" {
  expression = vault("kv/data/do", "consul_gossip_key")
}

variable "region" {
  type      = string
  default   = "ams3"
  sensitive = false
}

variable "size" {
  type    = string
  default = "s-1vcpu-512mb-10gb"
}

variable "base_image_name" {
  type      = string
  sensitive = false
  default   = "20.04 (LTS) x64"
}

local "do_token" {
  expression = vault("digitalocean/data/tokens", "packer")
  sensitive  = true
}

local "docker_registry_pass" {
  expression = vault("kv/data/github", "ghcr_token")
  sensitive  = true
}

local "docker_registry_username" {
  expression = "brucellino"
  sensitive  = false
}

variable "vpc_uuid" {
  type      = string
  sensitive = false
  default   = "08a4d3ad-a229-40dd-8dd4-042bda3e09bc" # this is only available in AMS3 - a map is needed.
}

variable "docker_base_image" {
  type      = string
  sensitive = false
  default   = "public.ecr.aws/docker/library/alpine:3.18"
}

data "digitalocean-image" "base-ubuntu" {
  api_token = vault("digitalocean/data/tokens", "packer")
  name      = var.base_image_name
  region    = var.region
  type      = "distribution"
}


source "digitalocean" "server" {
  api_token          = local.do_token
  image              = data.digitalocean-image.base-ubuntu.image_id
  region             = var.region
  size               = var.size
  ssh_username       = "root"
  snapshot_name      = "consul_snap-${formatdate("YYYY-MM-DD-hh-mm", timestamp())}"
  snapshot_regions   = [var.region]
  droplet_agent      = true
  monitoring         = true
  private_networking = true
  droplet_name       = "consul-build-${formatdate("YYYY-MM-DD-hh-mm", timestamp())}"
  tags               = ["packer", "consul"]
  vpc_uuid           = var.vpc_uuid
}

source "docker" "server" {
  image  = var.docker_base_image
  commit = true
  changes = [
    "USER consul",
    "WORKDIR /home/consul",
    "EXPOSE 8500 8501 8502 8503 8443 8600 8601",
    "LABEL consul_version=${var.consul_version}",
    "LABEL org.opencontainers.image.source=https://github.com/brucellino/packer-templates",
    "LABEL org.opencontainers.image.description=\"Consul ${var.consul_version} image\"",
    "ENTRYPOINT [\"tini\", \"--\"]",
    "VOLUME /opt/consul/data",
    "CMD [\"/bin/consul\", \"agent\", \"-config-dir=/etc/consul.d/\"]"
  ]
  author = "brucellino@proton.me"
  volumes = {
    consul_data = "/opt/consul/data"
  }
  run_command = ["-d", "-i", "-t", "--entrypoint=/bin/sh", "--name=consul", "--", "{{.Image}}"]
}

build {
  name    = "server-consul"
  sources = ["source.digitalocean.server"]
  provisioner "ansible" {
    playbook_file   = "playbook.yml"
    extra_arguments = [
      "--extra-vars",
      "consul_version=${var.consul_version}",
      "is_server=true"
      ]
  }
}

build {
  name    = "server-docker"
  sources = ["source.docker.server"]
  provisioner "ansible" {
    playbook_file   = "playbook-docker.yml"
    extra_arguments = [
      "--extra-vars", "consul_version=${var.consul_version}",
      "-e", "is_server=true",
      "-e", "server_encrypt_key=${local.gossip_key}"
    ]
  }

  post-processors {
    post-processor "docker-tag" {
      repository = "ghcr.io/brucellino/consul"
      tags       = ["${var.consul_version}-latest"]
    }
    post-processor "docker-push" {
      login          = true
      login_password = local.docker_registry_pass
      login_username = local.docker_registry_username
      login_server   = "https://ghcr.io/${local.docker_registry_username}"
    }
  }
}
