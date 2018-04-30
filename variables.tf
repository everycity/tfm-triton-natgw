variable "namespace" {
  default = "global"
}

variable "stage" {
  default = "default"
}

variable "name" {
  default = "app"
}

variable "delimiter" {
  type    = "string"
  default = "-"
}

variable "attributes" {
  type    = "list"
  default = []
}

variable "tags" {
  type    = "map"
  default = {}
}

variable "network_public" {}
variable "network_private" {}

variable "ucarp_vhid" {}
variable "ucarp_pass" {}
variable "ucarp_vip" {}

variable "instance_package" {
	default = "test1-container-128"
}
