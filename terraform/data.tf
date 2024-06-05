data "aws_availability_zones" "available" {}

data "aws_region" "current" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["${var.ami_name}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "selected" {
  id = module.vpc.vpc_id
  tags = {
    Terraform = "true"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = {
    Private   = "true"
    Terraform = "true"
  }

}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = {
    Public    = "true"
    Terraform = "true"
  }

}

data "aws_route53_zone" "selected" {
  name         = "zabens.com"
}