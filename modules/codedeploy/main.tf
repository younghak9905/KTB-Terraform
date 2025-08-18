# CodeDeploy Application
resource "aws_codedeploy_app" "app" {
  name             = "${var.stage}-${var.servicename}-app"
  compute_platform = var.compute_platform

  tags = var.tags
}

# CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "deployment_group" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "${var.stage}-${var.servicename}-dg"
  service_role_arn      = aws_iam_role.codedeploy_service_role.arn

  deployment_config_name = var.deployment_config_name

  # ECS 배포 설정
  dynamic "ecs_service" {
    for_each = var.compute_platform == "ECS" ? [1] : []
    content {
      cluster_name = var.ecs_cluster_name
      service_name = var.ecs_service_name
    }
  }

  # EC2 배포 설정
  dynamic "ec2_tag_filter" {
    for_each = var.compute_platform == "Server" ? var.ec2_tag_filters : []
    content {
      key   = ec2_tag_filter.value.key
      type  = ec2_tag_filter.value.type
      value = ec2_tag_filter.value.value
    }
  }

  # Auto Rollback 설정
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  tags = var.tags
}

# CodeDeploy Service Role
resource "aws_iam_role" "codedeploy_service_role" {
  name = "${var.stage}-${var.servicename}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# CodeDeploy Service Role Policy Attachment
resource "aws_iam_role_policy_attachment" "codedeploy_service_role_policy" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = var.compute_platform == "ECS" ? "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS" : "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# S3 Bucket for Deployment Artifacts
resource "aws_s3_bucket" "deployment_artifacts" {
  bucket = "${var.stage}-${var.servicename}-codedeploy-artifacts"

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "deployment_artifacts_versioning" {
  bucket = aws_s3_bucket.deployment_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deployment_artifacts_encryption" {
  bucket = aws_s3_bucket.deployment_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}