packer {
  required_version = ">=1.7.0"
  required_plugins {
    docker = {
      source = "github.com/hashicorp/docker"
      version = "~> 1"
    }
  }
}

variable "version" {
  type        = string
  description = "Internal version of the image"
  default     = "latest"
}

locals {
  docker_password = vault("kv/data/github", "ghcr_token")
}

source "docker" "ubuntu2004" {
  image  = "ubuntu:20.04"
  commit = true
  changes = [
    "USER ubuntu",
    "LABEL version=${var.version}",
    "LABEL org.opencontainers.image.source https://github.com/brucellino/packer-templates"
  ]
}

build {
  sources = ["source.docker.ubuntu2004"]

  provisioner "shell" {
    inline = [
      "apt-get update -qq",
      "apt-get install -qq -y python3 python3-pip curl jq",
      "apt-get upgrade -y -qq",
      "curl -fSL https://github.com/aquasecurity/trivy/releases/download/v0.29.2/trivy_0.29.2_Linux-64bit.tar.gz | tar xz",
      "./trivy fs --exit-code 1 -s HIGH,CRITICAL /",
      "apt-get clean all"

    ]
  }

  post-processors {
    post-processor "docker-tag" {
      repository = "ghcr.io/brucellino/ubuntu"
      tags       = ["${source.name}-${var.version}"]
    }
    post-processor "docker-push" {
      login_server   = "ghcr.io"
      login_username = "brucellino"
      login_password = local.docker_password
    }
  }
}
