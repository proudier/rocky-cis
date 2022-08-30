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
variable "system_timezone" {
  description = "Timezone of the system. Any value from the `pytz.all_timezones` list is valid."
  type        = string
  default     = "America/Montreal"
}
variable "disk_size" {
  type = string
  default = "25G"
}

#
# Building host
#
variable "qemu_accelerator" {
  description = "Accelerator used by QEMU when building the image (eg. hvf, kvm)"
  type        = string
  default     = "kvm"
}
variable "qemu_display" {
  description = "QEMU display to use (eg. cocoa, gtk)"
  type        = string
  default     = "gtk"
}
