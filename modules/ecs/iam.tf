resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.cluster_name}-ecs-instance-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.cluster_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}


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



resource "aws_iam_role" "ecs_task_role" {
    name = "${var.cluster_name}-ecs-task"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ecs-tasks.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
  tags = merge(var.tags, {
    Name         = "${var.cluster_name}-ecs-task"
  })
}


resource "aws_iam_policy" "ecs_task_policy" {
  name        = "${var.cluster_name}-ecs-task-policy"
  description = "Policy for ECS Task logging and related permissions"
  policy      = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ecs_task_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.id
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}



resource "aws_iam_role" "ecs_task_execution_role" {
name = "${var.cluster_name}-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}