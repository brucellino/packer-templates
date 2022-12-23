# Ansible images
variable "docker_password" {
  type      = string
  sensitive = true
  default   = env("GITHUB_TOKEN")
}

variable "python_image_tag" {
  description = "Tag of the python image to use."
  default = "3.9-alpine"
}

variable "container_changes" {
  description = "List of changes to apply to containers when starting build."
  default = [
    "USER root",
    "LABEL VERSION=latest",
    "LABEL org.opencontainers.image.source https://github.com/brucellino/packer-templates",
    "ENTRYPOINT ansible-playbook"
  ]
}

source "docker" "amd64" {
  image = "arm64v8/python:${var.python_image_tag}"
  commit = true
  changes = var.container_changes
  run_command = [
    "-d", "-i", "-t", "--entrypoint=/bin/bash",
    "--name=ansible-amd64",
    "--", "{{ .Image }}"
  ]
}

source "docker" "arm64" {
  image = "python:${var.python_image_tag}"
  commit = true
  changes = var.container_changes
  run_command = [
    "-d", "-i", "-t", "--entrypoint=/bin/sh",
    "--name=ansible-arm64",
    "--", "{{ .Image }}"
  ]
}

build {
  sources = ["source.docker.arm64"]

  provisioner "shell" {
    inline = [
      "apk add curl jq",
      "pip install ansible",
      "which ansible",
      "ansible --version"
      // "curl -fSL https://github.com/aquasecurity/trivy/releases/download/v0.35.0/trivy_0.35.0_Linux-ARM64.tar.gz | tar xz",
      // "./trivy fs --exit-code 1 -s HIGH,CRITICAL /"
    ]
  }

  post-processors {
    post-processor "docker-tag" {
      repository = "ghcr.io/brucellino/ansible"
      tags       = ["${source.name}-latest"]
    }
    post-processor "docker-push" {
      login = true
      login_server   = "ghcr.io"
      login_username = "brucellino"
      login_password = var.docker_password
    }
  }
}
