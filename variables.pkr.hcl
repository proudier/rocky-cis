#
# Admin
#
variable "admin_user_name" {
  type = string
}
variable "admin_public_key" {
  type = string
}

#
# Target system
#
variable "hostname" {
  type = string
  default = "rockycis"
}
variable "disk_size" {
  type = string
  default = "25G"
}

#
# Building host
#
variable "qemu_accelerator" {
  type = string
  default = "kvm"
}
