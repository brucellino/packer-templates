packer {
  required_plugins {
    arm-image = {
      version = ">= 0.2.6"
      source = "github.com/solo-io/arm-image"
    }
  }
}

source "arm-image" "raspberry_pi_os" {
  iso_checksum = "5adcab7a063310734856adcdd2041c8d58f65c185a3383132bc758886528a93d"
  iso_url      = "https://downloads.raspberrypi.org/raspios_arm64/images/raspios_arm64-2022-04-07/2022-04-04-raspios-bullseye-arm64.img.xz"
}

build {
  sources = ["source.arm-image.raspberry_pi_os"]
}
