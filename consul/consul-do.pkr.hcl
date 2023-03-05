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

data "digitalocean-image" "base-ubuntu" {
  name   = var.base_image_name
  region = var.region
  type   = "distribution"
}


source "digitalocean" "ubuntu" {
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
}

build {
  sources = ["source.digitalocean.ubuntu"]
}
