# CodeDeploy for Backend Deployment
module "codedeploy" {
  source = "../modules/codedeploy"

  stage       = var.stage
  servicename = var.servicename
  
  compute_platform       = "ECS"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  
  # ECS 설정 (Stage/Prod 환경에서 사용)
  ecs_cluster_name = "${var.stage}-${var.servicename}-cluster"
  ecs_service_name = "${var.stage}-${var.servicename}-backend"

  tags = var.tags
}

# GitLab Runner에 CodeDeploy 권한 추가
resource "aws_iam_policy" "gitlab_codedeploy_policy" {
  name        = "${var.stage}-${var.servicename}-gitlab-codedeploy-policy"
  description = "Policy for GitLab Runner to use CodeDeploy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${module.codedeploy.s3_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = module.codedeploy.s3_bucket_arn
      }
    ]
  })

  tags = var.tags
}

# GitLab Runner IAM 역할에 CodeDeploy 정책 연결
resource "aws_iam_role_policy_attachment" "gitlab_codedeploy_policy_attachment" {
  role       = module.iam_role.ec2-iam-role.name
  policy_arn = aws_iam_policy.gitlab_codedeploy_policy.arn
}