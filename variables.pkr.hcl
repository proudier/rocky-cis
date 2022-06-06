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
# System
#
variable "hostname" {
  type = string
  default = "rockycis"
}
variable "disk_size" {
  type = string
  default = "25G"
}
