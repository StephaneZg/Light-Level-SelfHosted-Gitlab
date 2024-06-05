output "instance_id" {
  value = aws_instance.gitlab.id
}

output "public_ip" {
  value = aws_eip.gitlab_vpc_in_ip[0].public_ip
}

output "private_ip" {
  value = aws_instance.gitlab.private_ip
}

# output "iam_instance_role_arn" {
#   value = try(aws_iam_role.gitlab.arn, "")
# }

# output "data_disk_volume_ids" {
#   value = aws_ebs_volume.gitlab.id
# }
