output "codedeploy_app_name" {
  description = "CodeDeploy application name"
  value       = aws_codedeploy_app.app.name
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy deployment group name"
  value       = aws_codedeploy_deployment_group.deployment_group.deployment_group_name
}

output "codedeploy_service_role_arn" {
  description = "CodeDeploy service role ARN"
  value       = aws_iam_role.codedeploy_service_role.arn
}

output "s3_bucket_name" {
  description = "S3 bucket name for deployment artifacts"
  value       = aws_s3_bucket.deployment_artifacts.bucket
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN for deployment artifacts"
  value       = aws_s3_bucket.deployment_artifacts.arn
}