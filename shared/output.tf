# shared/outputs.tf


# Bastion 출력
output "bastion_id" {
  description = "Bastion EC2 인스턴스 ID"
  value       = module.bastion.bastion_id
}

output "bastion_public_ip" {
  description = "Bastion 서버의 퍼블릭 IP 주소"
  value       = module.bastion.bastion_public_ip
}

output "bastion_private_ip" {
  description = "Bastion 서버의 프라이빗 IP 주소"
  value       = module.bastion.bastion_private_ip
}

output "bastion_security_group_id" {
  description = "Bastion 보안 그룹 ID"
  value       = module.bastion.bastion_security_group_id
}

# VPC 관련 출력
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.my_vpc.id
}

output "vpc_cidr" {
  description = "VPC CIDR 블록"
  value       = aws_vpc.my_vpc.cidr_block
}

output "route_table_ids" {
  description = "VPC 라우팅 테이블 ID 목록"
  value       = [
    aws_route_table.public_route_table.id,
    aws_route_table.private_route_table.id
  ]
}
/*

# GitLab 출력
output "gitlab_id" {
  description = "GitLab EC2 인스턴스 ID"
  value       = module.gitlab.gitlab_id
}

output "gitlab_private_ip" {
  description = "GitLab 서버의 프라이빗 IP 주소"
  value       = module.gitlab.gitlab_private_ip
}

output "gitlab_security_group_id" {
  description = "GitLab 보안 그룹 ID"
  value       = module.gitlab.gitlab_security_group_id
}

output "gitlab_data_volume_id" {
  description = "GitLab 데이터 EBS 볼륨 ID"
  value       = module.gitlab.data_volume_id
}*/