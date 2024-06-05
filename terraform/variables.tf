variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "number of public subnet to create in the VPC"
  type        = number
  default     = 2
}

variable "private_subnets" {
  description = "number of private subnet to create in the VPC"
  type        = number
  default     = 2
}

variable "create_instance" {
  description = "Should we create the instance ?"
  type        = bool
  default     = true
}

variable "create_alb" {
  description = "Should we create an application load balancer ?"
  type        = bool
  default     = true
}

variable "create_key_pair" {
  description = "Should we create a key pair file"
  type        = bool
  default     = false
}


variable "create_nat_gateway" {
  description = "Should we create a nat gateway ?"
  type        = bool
  default     = true
}

variable "ami_name" {
  description = "AMI to use for the EC2 instance"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
}

variable "create_vpc" {
  description = "Should we create a vpc ?"
  type        = bool
  default     = true
}

variable "external_ssh_port" {
  type    = string
  default = "2222"
}

variable "prefix" {
  default = "gitlab"
}

variable "default_allowed_ingress_cidr_blocks" {
  description = "Default cidr bloc allowed to fecth from deployed ressource"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "external_ssh_allowed_ingress_cidr_blocks" {
  description = "External cidr allowed to acces resource via SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "http_allowed_ingress_cidr_blocks" {
  description = "External cidr alloweeb to accss resource via hhtp or https"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}