
packer {
  required_version = ">= 1.8.0, < 2.0.0"
  required_plugins {
    qemu = {
      version = ">= 1.0.10"
      source  = "github.com/hashicorp/qemu"
    }
    sshkey = {
      version = ">= 1.0.1"
      source  = "github.com/ivoronin/sshkey"
    }
  }
}

locals {
  packer_user_name = "packer"
  # A default password is passed when creating the packer user but the actual password
  # get randomized first thing in the Post section. So this static password is
  # extremely ephemeral
  packer_user_pwd = "WillBeRandomizedInPostAndCisPreventsPasswordSshConnection"
  # Same for admin password
  admin_user_pwd = "WeKnowWhatWeAreButKnowNotWhatWeMayBe"
}

data "sshkey" "packer" {}

source "qemu" "vm" {
  accelerator      = var.qemu_accelerator
  machine_type     = "q35"
  display          = var.qemu_display
  cpus             = 4
  memory           = "4096"
  disk_size        = var.disk_size
  disk_compression = true
  output_directory = "packer_output/"
  headless         = false
  # DVD image is required for `%addon org_fedora_oscap`
  iso_url           = "https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8.9-x86_64-dvd1.iso"
  iso_checksum      = "sha256:1abe38fd11279879e3e7658ef748c1ef06ee763351a53bb424020ec053c50d0b"
  boot_command      = ["<up><tab> inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/kickstart.cfg <enter><wait>"]
  boot_key_interval = "2ms"
  boot_wait         = "1s"
  http_content = {
    "/kickstart.cfg" = templatefile("kickstart.cfg.pkrtpl.hcl", {
      "packer_user_name"  = local.packer_user_name
      "packer_user_pwd"   = local.packer_user_pwd
      "packer_public_key" = data.sshkey.packer.public_key
      "admin_user_name"   = var.admin_user_name
      "admin_user_pwd"    = local.admin_user_pwd
      "admin_public_key"  = var.admin_public_key
      "hostname"          = var.hostname
      "system_timezone"   = var.system_timezone
    })
  }
  ssh_username              = local.packer_user_name
  ssh_private_key_file      = data.sshkey.packer.private_key_path
  ssh_clear_authorized_keys = true
  ssh_timeout               = "30m"
  ssh_handshake_attempts    = 100
}

build {
  sources = ["source.qemu.vm"]
}
