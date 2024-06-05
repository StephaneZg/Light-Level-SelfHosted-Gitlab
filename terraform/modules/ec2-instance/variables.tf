variable "prefix" {
  type    = string
  default = null
}

variable "instance_name" {
  type    = string
  default = null
}

variable "elastic_ip_allocation_id" {
  type = bool
}

variable "ami_id" {
  type    = string
  default = null
}

variable "node_type" {
  type    = string
  default = "gitlab-main-instance"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "ssh_key_name" {
  type    = string
  default = "gitlab-key-pair"
}

variable "disk_type" {
  type    = string
  default = "gp3"
}

variable "disk_size" {
  type    = string
  default = "100"
}

variable "disk_iops" {
  type    = number
  default = null
}
variable "disk_kms_key_arn" {
  type    = string
  default = null
}

variable "data_disks" {
  type    = any
  default = []
}

variable "disk_encrypt" {
  type    = bool
  default = false
}

variable "subnet_ids" {
  type    = list(string)
  default = null
}

variable "additional_tags" {
  type    = map(any)
  default = {}
}

variable "disk_delete_on_termination" {
  type    = bool
  default = true
}

variable "skip_destroy" {
  type    = bool
  default = false
}