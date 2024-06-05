locals {
  create_public_subnets  = var.create_vpc && var.len_public_subnets > 0
  create_private_subnets = var.create_vpc && var.len_private_subnets > 0
  private_rtb_name       = "gitlabInfra-private-rtb"
  public_rtb_name        = "gitlabInfra-public-rtb"
  igw_name               = "gitlabInfra-igw"
  nat_gw_name            = "gitlabInfra-nat-gw"
  eip_name               = "gitlabInfra-ngw-eip"

  private_subnet_ids = {
    for idx, subnet_id in aws_subnet.private_subnets[*].id : idx => subnet_id
  }

  public_subnet_ids = {
    for idx, subnet_id in aws_subnet.public_subnets[*].id : idx => subnet_id
  }
}


resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true


  tags = {
    Name = var.vpc_name
  }
}

#######################################################################
# SUBNETS
#######################################################################
resource "aws_subnet" "private_subnets" {
  count = var.len_private_subnets

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(try(var.vpc_cidr, "10.0.0.0/16"), 8, count.index)
  availability_zone = tolist(data.aws_availability_zones.available.names)[count.index]

  tags = {
    Name    = "private-subnet-${count.index}"
    Private = true
  }
}

resource "aws_subnet" "public_subnets" {
  count = var.len_public_subnets

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(try(var.vpc_cidr, "10.0.0.0/16"), 8, count.index + 100)
  availability_zone       = tolist(data.aws_availability_zones.available.names)[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name   = "public-subnet-${count.index}"
    Public = true
  }
}

#######################################################################
# ROUTE TABLES
#######################################################################
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name = local.public_rtb_name
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = local.private_rtb_name
  }
}

#######################################################################
# ROUTE TABLES ASSOCIATION
#######################################################################
resource "aws_route_table_association" "public" {
  for_each = local.public_subnet_ids

  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = each.value
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnet_ids

  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = each.value
}

#######################################################################
# INTERNET GATEWAY
#######################################################################
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = local.igw_name
  }
}

#######################################################################
# ELASTIC IP
#######################################################################
resource "aws_eip" "nat_gateway_eip" {
  domain     = "vpc"
  tags = {
    Name = local.eip_name
  }
}

#######################################################################
# NAT GATEWAY
#######################################################################
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id
  tags = {
    Name = local.nat_gw_name
  }
}
