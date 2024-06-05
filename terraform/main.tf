module "vpc" {
  source              = "./modules/vpc"
  len_private_subnets = 2
  len_public_subnets  = 2
}

module "gitlab_instance" {
  source                     = "./modules/ec2-instance"
  elastic_ip_allocation_id   = true
  subnet_ids                 = [try(data.aws_subnets.public.ids[0], data.aws_subnets.public.ids)]
  ami_id                     = data.aws_ami.ubuntu.id
  disk_size                  = "150"
  disk_delete_on_termination = false
  security_group_ids         = [aws_security_group.ingress_external_ssh.id, aws_security_group.internal_networking.id, aws_security_group.gitlab_external_http_https.id, aws_security_group.gitlab_external_git_ssh.id, aws_security_group.gitlab_external_postgresql.id]
  disk_iops                  = 3000

  instance_type = "t3.large"
  instance_name = "main-instance"
  prefix        = var.prefix
  skip_destroy  = true
}

# module "bastion_instance" {
#   source                     = "./modules/ec2-instance"
#   elastic_ip_allocation_id   = false
#   subnet_ids                 = [try(data.aws_subnets.public.ids[0], data.aws_subnets.public.ids)]
#   ami_id                     = data.aws_ami.ubuntu.id
#   disk_size                  = "25"
#   disk_delete_on_termination = true
#   security_group_ids         = [aws_security_group.internal_networking.id, aws_security_group.ingress_external_ssh.id]
#   disk_iops                  = 3000

#   instance_name = "${var.prefix}-bastion"
#   prefix        = var.prefix
# }

resource "aws_security_group" "internal_networking" {
  name   = "${var.prefix}-internal-networking"
  vpc_id = data.aws_vpc.selected.id

  ingress {
    description = "Open internal networking for VMs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  tags = {
    Name = "${var.prefix}-internal-networking"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ingress_external_ssh" {
  name   = "${var.prefix}-external-ssh"
  vpc_id = data.aws_vpc.selected.id

  ingress {
    description = "Open SSH access for VMs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = coalescelist(var.http_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = coalescelist(var.http_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }

  tags = {
    Name = "${var.prefix}-external-ssh"
  }


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "gitlab_external_git_ssh" {
  name_prefix = "${var.prefix}-external-git-ssh-"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "External Git SSH access for ${var.prefix}"
    from_port   = var.external_ssh_port
    to_port     = var.external_ssh_port
    protocol    = "tcp"
    cidr_blocks = coalescelist(var.http_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = coalescelist(var.http_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }

  tags = {
    Name = "${var.prefix}-external-git-ssh"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "gitlab_external_http_https" {
  name_prefix = "${var.prefix}-external-http-https-"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "Enable HTTP access for select VMs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = coalescelist(var.http_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }

  ingress {
    description = "Enable HTTPS access for select VMs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = coalescelist(var.http_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = coalescelist(var.http_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }

  tags = {
    Name = "${var.prefix}-external-http-https"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "gitlab_external_postgresql" {
  name_prefix = "${var.prefix}-external-postgresql"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "Enable database access for select VMs"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = coalescelist(var.http_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = coalescelist(var.http_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }

  tags = {
    Name = "${var.prefix}-external-postgresql"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "gitlab" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "gitlab.zabens.com"
  type    = "A"
  ttl     = 300
  records = [module.gitlab_instance.public_ip]
}

resource "aws_route53_record" "gitlab_registry" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "registry.gitlab.zabens.com"
  type    = "A"
  ttl     = 300
  records = [module.gitlab_instance.public_ip]
}

resource "aws_route53_record" "gitlab_mattermost" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "mattermost.gitlab.zabens.com"
  type    = "A"
  ttl     = 300
  records = [module.gitlab_instance.public_ip]
}