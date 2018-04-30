# terraform-triton-natgw

Terraform module for provisioning a HA pair of ucarp NAT gateway instances.

<aside class="notice">
Note: Due to ucarp's requirement for multicast, the private network cannot
be a fabric network. There is a fork of ucarp which supports UDP unicast
which can be used as an alternative (https://github.com/zevenet/ucarp),
with the obvious downsides being that you have to build it, and you have
to specify the partner UDP IP addresses, which can't be done in one pass
with terraform.
</aside>

## Usage

Include this repository as a module in your existing terraform code:

```hcl
data "triton_network" "public" {
        name = "public"
}

data "triton_network" "private" {
        name = "private"
}

module "natgw" {
  source	= "git::https://github.com:everycity/terraform-triton-natgw.git?ref=master"
  namespace	= "global"
  name		= "app"
  stage		= "prod"
  attributes	= "natgw"

  network_public  = "${data.triton_network.public.id}"
  network_private = "${data.triton_network.private.id}"

  ucarp_vhid  = "1"
  ucarp_pass  = "password"
  ucarp_vip   = "192.168.0.254"
}
```

<aside class="warning">
You will need to set allow_ip_spoofing and allow_mac_spoofing on the instances after they have
been provisioned in order for ucarp to work correctly.
</aside>

## Input

<!--------------------------------REQUIRE POSTPROCESSING-------------------------------->
|  Name |  Default  |  Description  |
|:------|:----------|:--------------|
| attributes |[] | Additional attributes (e.g. `policy` or `role`)|
| delimiter |"-" | Delimiter to be used between `name`, `namespace`, `stage`, etc.|
| enabled |"true" | Set to false to prevent the module from creating any resources|
| name |__REQUIRED__ | Solution name, e.g. 'app' or 'jenkins'|
| namespace |__REQUIRED__ | Namespace, which could be your organization name, e.g. 'everycity'|
| stage |__REQUIRED__ | Stage, e.g. 'prod', 'staging', 'dev', or 'test'|
| tags |{} | Additional tags (e.g. `map('BusinessUnit`,`XYZ`)|
| instance_package | "test1-container-128" | Triton package to use for instances |
| network_public | "" | Triton network (id) to use for public network |
| network_private | "" | Triton network (id) to use for private network |
| ucarp_vhid | "1" | UCarp Virtual IP identifier (1-255) |
| ucarp_pass | __REQUIRED__ | UCarp Password |
| ucarp_vip | __REQUIRED__ | UCarp Virtual Private IP |


## Output

| Name             |        Description                                               |
|:-----------------|:-----------------------------------------------------------------|
| id               | Instance IDs                                                     |

