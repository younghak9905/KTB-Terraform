# Assume Role Policy 문서 생성 (동일)
data "aws_iam_policy_document" "ecs_instance_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# 기존 IAM Role이 있을 경우 데이터 소스로 가져옴
data "aws_iam_role" "ecs_instance_role_existing" {
  count = var.import_existing ? 1 : 0
  name  = var.ecs_instance_role_name
}

# IAM Role 생성 (import_existing이 false인 경우)
resource "aws_iam_role" "ecs_instance_role" {
  count               = var.import_existing ? 0 : 1
  name                = var.ecs_instance_role_name
  assume_role_policy  = data.aws_iam_policy_document.ecs_instance_assume_role.json
}

# 로컬 변수로 실제 사용될 Role 이름 결정
locals {
  ecs_instance_role_name_used = var.import_existing ? data.aws_iam_role.ecs_instance_role_existing[0].name : aws_iam_role.ecs_instance_role[0].name
}

# IAM Role Policy Attachment (생성하는 경우만)
resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment" {
  count      = var.import_existing ? 0 : 1
  role       = local.ecs_instance_role_name_used
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# 기존 Instance Profile이 있을 경우 데이터 소스로 가져옴
data "aws_iam_instance_profile" "ecs_instance_profile_existing" {
  count = var.import_existing ? 1 : 0
  name  = var.ecs_instance_profile_name
}

# Instance Profile 생성 (import_existing이 false인 경우)
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  count = var.import_existing ? 0 : 1
  name  = var.ecs_instance_profile_name
  role  = local.ecs_instance_role_name_used
}

# 실제 사용될 Instance Profile 이름
locals {
  ecs_instance_profile_name_used = var.import_existing ? data.aws_iam_instance_profile.ecs_instance_profile_existing[0].name : aws_iam_instance_profile.ecs_instance_profile[0].name
}
