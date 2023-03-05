packer {
  required_plugins {
    digitalocean = {
      version = ">= v1.1.0"
      source  = "github.com/digitalocean/digitalocean"
    }
  }
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


variable "vpc_uuid" {
  type      = string
  sensitive = false
  default   = "08a4d3ad-a229-40dd-8dd4-042bda3e09bc" # this is only available in AMS3 - a map is needed.
}

data "digitalocean-image" "base-ubuntu" {
  name   = var.base_image_name
  region = var.region
  type   = "distribution"
}


source "digitalocean" "server" {
  api_token          = local.do_token
  image              = data.digitalocean-image.base-ubuntu.image_id
  region             = var.region
  size               = var.size
  ssh_username       = "root"
  snapshot_name      = "consul_snap"
  snapshot_regions   = [var.region]
  droplet_agent      = true
  monitoring         = true
  private_networking = true
  droplet_name       = "consul-build"
  tags               = ["packer", "consul"]
  vpc_uuid           = var.vpc_uuid
}

build {
  name    = "server"
  sources = ["source.digitalocean.server"]
  provisioner "ansible" {
    playbook_file = "playbook.yml"
  }
}
