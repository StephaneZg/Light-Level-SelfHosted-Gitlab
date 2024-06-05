#####################################################################
# EC2 INTNACE AND CORRELATED RESOURCES
#####################################################################
resource "aws_instance" "gitlab" {
  instance_type          = var.instance_type
  ami                    = var.ami_id
  key_name               = aws_key_pair.connect.key_name
  vpc_security_group_ids = compact(var.security_group_ids)

  subnet_id = var.subnet_ids != null ? element(tolist(var.subnet_ids), 0) : null

  root_block_device {
    volume_size = var.disk_size
    iops        = var.disk_iops
    volume_type = var.disk_type

    delete_on_termination = false

    tags = merge({
      Name = "${var.prefix}-${var.instance_name}-root"
    }, var.additional_tags)
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = merge({
    Name               = "${var.prefix}-${var.instance_name}"
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = var.node_type
  }, var.additional_tags)

  lifecycle {
    ignore_changes = [
      ami
    ]
  }
}

locals {
  instance_eip_name = "${var.prefix}-${var.instance_name}-eip"
}

resource "tls_private_key" "key_pair_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.key_pair_private_key.private_key_pem
  filename        = "${var.ssh_key_name}.pem"
  file_permission = "0600"
}

resource "aws_key_pair" "connect" {
  key_name   = var.ssh_key_name
  public_key = tls_private_key.key_pair_private_key.public_key_openssh

  lifecycle {
    ignore_changes = [key_name]
  }
}

resource "aws_eip" "gitlab_vpc_in_ip" {
  count  = var.elastic_ip_allocation_id ? 1 : 0
  domain = "vpc"
  tags = {
    Name = local.instance_eip_name
  }
}

resource "aws_eip_association" "gitlab" {
  count = var.elastic_ip_allocation_id ? 1 : 0

  instance_id   = aws_instance.gitlab.id
  allocation_id = aws_eip.gitlab_vpc_in_ip[0].id
}

#####################################################################
# ROLES POLICIES AND INSTANCES PROFILE
#####################################################################
resource "aws_iam_instance_profile" "gitlab" {
  name = "${var.prefix}-${var.instance_name}-profile"
  role = aws_iam_role.gitlab.name
}

resource "aws_iam_role" "gitlab" {
  name = "${var.prefix}-${var.instance_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "gitlab_acces" {
  name = "${var.prefix}-${var.instance_name}-policy"
  role = aws_iam_role.gitlab.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::gitlab-selfhosted-stephane/*"
      },
    ]
  })
}

#####################################################################
# EBS VOLUMES AND ATTACHMENT
#####################################################################
# resource "aws_ebs_volume" "gitlab" {

#   type              = var.disk_type
#   size              = var.disk_size
#   availability_zone = "us-east-1a"

#   tags = {
#     Name                       = "${var.instance_name}-volume"
#     gitlab_node_data_disk_role = "${var.prefix}-${var.instance_name}"
#   }
# }

# resource "aws_volume_attachment" "gitlab" {

#   device_name                    = "/dev/sdf"
#   volume_id                      = aws_ebs_volume.gitlab.id
#   instance_id                    = aws_instance.gitlab.id
# }



