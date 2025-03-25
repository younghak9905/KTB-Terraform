output "ecs_cluster_id" {
  description = "생성된 ECS 클러스터 ARN"
  value       = aws_ecs_cluster.this.id
}

output "ecs_cluster_name" {
  description = "생성된 ECS 클러스터 이름"
  value       = aws_ecs_cluster.this.name
}

output "ecs_instance_profile" {
  description = "ECS 인스턴스에 사용된 IAM 인스턴스 프로파일 이름"
  value       = aws_iam_instance_profile.ecs_instance_profile.name
}

output "autoscaling_group_name" {
  description = "ECS 인스턴스용 Auto Scaling Group 이름"
  value       = aws_autoscaling_group.ecs_instances.name
}

output "task_definition_arn" {
  description = "생성된 ECS Task Definition ARN"
  value       = aws_ecs_task_definition.task.arn
}

output "ecs_service_name" {
  description = "생성된 ECS Service 이름"
  value       = aws_ecs_service.service.name
}