# Define composite variables for resources
module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.2.1"
  namespace  = "${var.namespace}"
  name       = "${var.name}"
  stage      = "${var.stage}"
  delimiter  = "${var.delimiter}"
  attributes = "${var.attributes}"
  tags       = "${merge("${var.tags}", map("role", "nat-gw"))}"
}

data "triton_image" "image" {
  name         = "minimal-64-lts"
  version      = "17.4.0"
  most_recent  = true
}

data "template_file" "user_script" {
  template     = "${file("${path.module}/user_script.sh")}"

  vars {
    ucarp_vhid = "${var.ucarp_vhid}"
    ucarp_pass = "${var.ucarp_pass}"
    ucarp_vip  = "${var.ucarp_vip}"
  }
}

resource "triton_machine" "nat-gw" {
  count        = 2

  name         = "oubound-nat-gw${count.index + 1}"
  package      = "${var.instance_package}"
  image        = "${data.triton_image.image.id}"

  networks     = ["${var.network_public}", "${var.network_private}"]
  user_script  = "${data.template_file.user_script.rendered}"
  affinity     = ["role!=nat-gw"]

  tags         = "${module.label.tags}"
}


