output "asg_id" {
  description = "The ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.id
}

output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}
