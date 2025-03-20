output "ecs_cluster_id" {
  description = "The ARN of the ECS Cluster"
  value       = aws_ecs_cluster.this.arn
}

output "ecs_cluster_name" {
  description = "The name of the ECS Cluster"
  value       = aws_ecs_cluster.this.name
}

output "launch_template_id" {
  description = "The ID of the launch template for ECS container instances"
  value       = aws_launch_template.ecs_launch_template.id
}

output "launch_template_version" {
  description = "The default version of the launch template"
  value       = aws_launch_template.ecs_launch_template.latest_version
}
