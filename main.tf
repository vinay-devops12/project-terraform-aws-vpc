resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true 

  tags = merge (
    var.vpc_tags,    ## vpc gate_way 
    local.common_tags
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags =merge (
    var.ig_tags,  ## this use for internet gate_way 
    local.common_tags 

  )
}


## public-subnet

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  count                   = length(var.public_subnet_cidrs)
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index] #    us-east-1a, us-east-1b 
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    var.public_subnet_tags,
    {
      Name = "${local.common_name}-public-${var.azs[count.index]}"
    }
  )
}

# 2. Create the Private Subnet

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]
   map_public_ip_on_launch = false
  
  tags = merge(
    local.common_tags,
    var.private_subnet_tags,
    {
      Name = "${local.common_name}-private-${var.azs[count.index]}"
    }
  )
}
  

  
resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone =local.az_names[count.index]
   map_public_ip_on_launch = false
  
  tags = merge(
    local.common_tags,
    var.database_subnet_tags,
    {
      Name = "${local.common_name}-database-${var.azs[count.index]}"
    }
  )
}
  
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
     local.common_tags,
     var.public_route_table_tags,

     {
      Name = "${local.common_name}-public"
     }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    var.private_route_table_tags,

    {
      Name = "${local.common_name}-private"
    }
  )
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    var.database_route_table_tags,
    {
      Name = "${local.common_name}-database"
    }
  )
}


   ## route_table association

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# 1. Allocate the Elastic IP (EIP)


resource "aws_eip" "nat" {
  domain     = "vpc"
 
  tags = merge(
    local.common_tags,
     var.eip_tags,

     {
      Name = "${local.common_name}-nat"
     }
  )
}


## nat_gateway


resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    local.common_tags,
    var.nat_gateway_tags,  

  )
    depends_on = [ aws_internet_gateway.main ]   
}

## public internet_gate way

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}


resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}


resource "aws_route" "database" {
  route_table_id         = aws_route_table.database.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}


## peering

# Create the VPC Peering Connection
resource "aws_vpc_peering_connection" "default" {
  vpc_id        = aws_vpc.main.id           ## requester
  count =   var.is_peering_required ? 1:0  # is true one given
  peer_vpc_id   = data.aws_vpc.default.id  ## accepter
  auto_accept   = true  ## use same account and same region

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

 tags = merge ( 
  var.aws_vpc_peering_tags,
  local.common_tags,
  {
    Name = "${local.common_name}-default"
  }

)

}


# 2. Route from accepter VPC to Accepter VPC
resource "aws_route" "public_peering" {
  count = var.is_peering_required ? 1:0
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[ count.index ].id
}






