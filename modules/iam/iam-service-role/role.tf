#ec2 Role
resource "aws_iam_role" "ec2-iam-role" {
  name ="aws-iam-${var.stage}-${var.servicename}-ec2-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = var.tags

}

resource "aws_iam_instance_profile" "ec2-iam-role-profile" {
  name = "aws-iam-${var.stage}-${var.servicename}-ec2-role-profile"
  role = aws_iam_role.ec2-iam-role.name
}

# modules/iam/iam-service-role/policy.tf 생성 (파일이 없는 경우)

# SSM 접근을 위한 정책 생성
resource "aws_iam_policy" "ssm_policy" {
  name        = "aws-iam-${var.stage}-${var.servicename}-ssm-policy"
  description = "Policy for SSM access and ECS instance management"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssm:ListInstanceAssociations",
          "ssm:DescribeInstanceProperties",
          "ssm:DescribeDocumentParameters",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "ecs:ListClusters",
          "ecs:ListContainerInstances",
          "ecs:DescribeContainerInstances",
          "ec2:DescribeInstances"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
  
  tags = var.tags
}

# EC2 IAM 역할에 SSM 정책 연결
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy_attachment" {
  role       = aws_iam_role.ec2-iam-role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}

# EC2 IAM 역할에 기본 Amazon EC2 컨테이너 서비스 정책 연결
resource "aws_iam_role_policy_attachment" "ec2_ecs_policy_attachment" {
  role       = aws_iam_role.ec2-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

/*resource "aws_iam_role" "terraform_backend_role" {
  name = "TerraformS3Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.aws_account_id}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "terraform_backend_attach" {
  role       = aws_iam_role.terraform_backend_role.name
  policy_arn = aws_iam_policy.terraform_backend_policy.arn
}*/