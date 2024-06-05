variable "vpc_name" {
  description = "Name to use for the VPC"
  type        = string
  default     = "gitlab-VPC"
}

variable "vpc_cidr" {
  description = "CIDR to use for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "len_public_subnets" {
  description = "number of public subnet to create in the VPC"
  type        = number
  default     = 1
}

variable "len_private_subnets" {
  description = "number of private subnet to create in the VPC"
  type        = number
  default     = 1
}

variable "create_nat_gateway" {
  description = "Should we create a nat gateway ?"
  type        = bool
  default     = true
}

variable "create_vpc" {
  description = "Should we create a vpc ?"
  type        = bool
  default     = true
}