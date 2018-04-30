# terraform-triton-natgw

Terraform module for provisioning a HA pair of ucarp NAT gateway instances

## Usage

Include this repository as a module in your existing terraform code:

```hcl
module "natgw" {
  source	= "git::https://github.com:everycity/terraform-triton-natgw.git?ref=master"
  namespace	= "global"
  name		= "app"
  stage		= "prod"
  attributes	= "natgw"

  TODO
}
```

## Input

|  Name              |   Default      |                   Description              |
|:-------------------|:--------------:|:-------------------------------------------|
| namespace          | `global`       | Namespace (_e.g._ `global`)                |
| stage              | `default`      | Name (_e.g._ `prod`, `dev`, `staging`      |

etc

## Output

| Name             |        Description                                               |
|:-----------------|:-----------------------------------------------------------------|
| id               | Instance IDs                                                     |

