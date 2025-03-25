# shared/modules/bastion/outputs.tf

output "bastion_id" {
  description = "ID of the bastion EC2 instance"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion"
  value       = aws_eip.bastion.public_ip
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion_sg.id
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion"
  value       = aws_instance.bastion.private_ip
}