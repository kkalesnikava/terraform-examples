variable "vpcs" {
  description = "Map of VPCs and subnets to create"
  type = map(object({
    region          = string
    vpc_cidr        = string
    private_subnets = list(string)
    public_subnets  = list(string)
    tags            = map(string)
  }))

  default = {
    dev = {
      region   = "eu-south-1"
      vpc_cidr = "10.10.0.0/16"
      private_subnets = [
        "10.10.0.0/20",
        "10.10.16.0/20",
        "10.10.32.0/20",
        "10.10.48.0/20",
        "10.10.64.0/20",
      ]
      public_subnets = [
        "10.10.80.0/24",
        "10.10.81.0/24",
        "10.10.82.0/24",
      ]
      tags = { env = "dev" }
    }
    staging = {
      region   = "us-east-1"
      vpc_cidr = "10.20.0.0/16"
      private_subnets = [
        "10.20.0.0/20",
        "10.20.16.0/20",
        "10.20.32.0/20"
      ]
      public_subnets = [
        "10.20.48.0/24",
        "10.20.49.0/24"
      ]
      tags = { env = "staging" }
    }
  }
}

variable "azs_by_region" {
  description = "Map of AWS regions to their available AZs"
  type        = map(list(string))
  default = {
    "eu-south-1" = [
      "eu-south-1a",
      "eu-south-1b",
    ]
    "us-east-1" = [
      "us-east-1a",
      "us-east-1b",
      "us-east-1c",
      "us-east-1d",
      "us-east-1e",
      "us-east-1f",
    ]
  }
}

locals {
  subnets = merge(
    flatten([
      for env, vpc_conf in var.vpcs : [
        # Private subnets
        [for idx, cidr in vpc_conf.private_subnets : {
          "${env}-private-${idx}" = {
            subnet_type = "private"
            name        = "${env}-private-${idx}"
            cidr        = cidr
            az          = var.azs_by_region[vpc_conf.region][idx % length(var.azs_by_region[vpc_conf.region])]
            region      = vpc_conf.region
            vpc_cidr    = vpc_conf.vpc_cidr
            tags        = vpc_conf.tags
          }
        }],
        # Public subnets  
        [for idx, cidr in vpc_conf.public_subnets : {
          "${env}-public-${idx}" = {
            subnet_type = "public"
            name        = "${env}-public-${idx}"
            cidr        = cidr
            az          = var.azs_by_region[vpc_conf.region][idx % length(var.azs_by_region[vpc_conf.region])]
            region      = vpc_conf.region
            vpc_cidr    = vpc_conf.vpc_cidr
            tags        = vpc_conf.tags
          }
        }]
      ]
    ])...
  )
}

output "subnets" {
  value = local.subnets
}
