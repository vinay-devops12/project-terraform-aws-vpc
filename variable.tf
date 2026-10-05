
## mandatory

variable "project"{
    type = string
}

variable "environment"{
    type = string
}

variable "vpc_cidr"{
    type = string
    default = "10.0.0.0/16"
}

## opttional

variable "vpc_tags"{
    type = map
    default = { }
}

variable "ig_tags"{
    type = map
    default = { }
}


variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_tags"{
 type = map
default = {}
}

variable "public_subnet_cidrs"{
  type = list
  default = [ "10.0.1.0/24","10.0.2.0/24" ]
}


variable "private_subnet_cidrs"{
  type = list
  default = [ "10.0.11.0/24","10.0.12.0/24" ]
}

variable "database_subnet_cidrs"{
  type = list
  default = [ "10.0.21.0/24","10.0.22.0/24" ]
}

variable "private_subnet_tags"{
    type = map
    default ={}
}

variable "database_subnet_tags"{
    type = map
    default ={}
}


## tags

variable "public_route_table_tags" {
    type = map
    default = {}
}

variable "private_route_table_tags" {
    type = map
    default = {}
}

variable "database_route_table_tags" {
    type = map
    default = {}
}

variable "eip_tags"{
 type = map
default = {}
}

variable "nat_gateway_tags"{
    type = map
    default = { }
}


variable "is_peering_required"{
    default = false
    type = bool
}


variable "aws_vpc_peering_tags"{
    default = { }
    type = map
}
