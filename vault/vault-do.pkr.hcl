packer {
  required_plugins {
    digitalocean = {
      version = ">= v1.2.0"
      source  = "github.com/digitalocean/digitalocean"
    }
    ansible = {
      version = "~> 1"
      source = "github.com/hashicorp/ansible"
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
  default   = "23.10 x64"
}

local "do_token" {
  expression = vault("digitalocean/data/tokens", "packer")
  sensitive  = true
}

local "autojoin_token" {
  expression = vault("digitalocean/data/tokens", "vault_auto_join")
  sensitive = true
}

local "build_tag" {
  expression = join("-", ["created", "at", formatdate("YYYY-MM-DD-hh-mm", timestamp())])
}

variable "vpc_uuid" {
  type      = string
  sensitive = false
  default   = "08a4d3ad-a229-40dd-8dd4-042bda3e09bc" # this is only available in AMS3 - a map is needed.
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
  snapshot_name      = "vault_snap-${formatdate("YYYY-MM-DD-hh-mm", timestamp())}"
  snapshot_regions   = [var.region]
  droplet_agent      = true
  monitoring         = true
  private_networking = true
  droplet_name       = "vault-build-${formatdate("YYYY-MM-DD-hh-mm", timestamp())}"
  tags               = ["packer", "vault", "auto-destroy", local.build_tag]
  vpc_uuid           = var.vpc_uuid
}

build {
  name    = "server"
  sources = ["source.digitalocean.server"]
  provisioner "ansible" {
    playbook_file = "playbook.yml"
    extra_arguments = [
      "--extra-vars",
      "region=${var.region}",
      "--extra-vars",
      "autojoin_token=${local.autojoin_token}"
    ]
  }
  provisioner "shell" {
    inline = [
      "ls -lht /etc/vault.d",
      "cat /etc/vault.d/vault.hcl"
    ]
  }
}
