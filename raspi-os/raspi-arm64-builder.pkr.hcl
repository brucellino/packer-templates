packer {
  required_plugins {
    arm = {
      source = "github.com/cdecoux/builder-arm"
      version = "1.0.0"
    }
  }
}

source "arm" "raspi-os" {
  file_urls = ["https://downloads.raspberrypi.org/raspios_arm64/images/raspios_arm64-2022-04-07/2022-04-04-raspios-bullseye-arm64.img.xz"]
  file_checksum_url = "https://downloads.raspberrypi.org/raspios_arm64/images/raspios_arm64-2022-04-07/2022-04-04-raspios-bullseye-arm64.img.xz.sha256"
  file_checksum_type = "sha256"
  file_target_extension = "xz"
  file_unarchive_cmd = ["xz", "--decompress", "$ARCHIVE_PATH"]
  image_build_method = "reuse"
  image_path = "raspios-bullseye.img"
  image_size = "10.0G"
  image_type = "dos"
  image_partitions {
    name = "boot"
    type = "c"
    start_sector = "2048"
    filesystem = "fat"
    size = "256M"
    mountpoint = "/boot/firmware"
  }
  image_partitions {
    name = "root"
    type = "83"
    start_sector = "503808"
    filesystem = "ext4"
    size = "36.82G"
    mountpoint = "/"
  }

  image_partitions {
    name = "minio"
    type = "83"
    start_sector = "78628864"
    filesystem = "ext4"
    size = "81.59G"
    mountpoint = "/minio"
  }

  image_partitions {
    name = "minio1"
    type = "83"
    start_sector = "78632960"
    filesystem = "ext4"
    size = "20.49G"
    mountpoint = "/minio1"
  }

  image_partitions {
    name = "minio2"
    type = "83"
    start_sector = "121604096"
    filesystem = "ext4"
    size = "19.56G"
    mountpoint = "/minio2"
  }

  image_partitions {
    name = "minio3"
    type = "83"
    start_sector = "162623488"
    filesystem = "ext4"
    size = "21.42G"
    mountpoint = "/minio3"
  }

  image_partitions {
    name = "minio4"
    type = "83"
    start_sector = "207548416"
    filesystem = "ext4"
    size = "21.12G"
    mountpoint = "/minio4"
  }



  image_chroot_env = ["PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"]
  qemu_binary_source_path = "/usr/bin/qemu-aarch64-static"
  qemu_binary_destination_path = "/usr/bin/qemu-aarch64-static"
}

build {
  sources = ["source.arm.raspi-os"]

  provisioner "shell" {
    inline = [
      "touch /tmp/test",
    ]
  }

}
