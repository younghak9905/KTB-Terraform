resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "ecs_task_${var.stage}-${var.servicename}"
  network_mode             = "bridge"  # EC2 모드에서는 bridge 모드 사용
  requires_compatibilities = ["EC2"]   # EC2 기반 실행
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_image
      cpu       = 128
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
     # logConfiguration = {
     #   logDriver = "awslogs"
     ##   options = {
     #     "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
     #     "awslogs-region"        = var.region
     #     "awslogs-stream-prefix" = "ecs"
     #   }
     # }
    }
  ])
}


resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.servicename}-ecs-task-role"
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

resource "aws_iam_role_policy_attachment" "ecs_task_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.servicename}-ecs-task-execution-role"
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
/*
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.servicename}"
  retention_in_days = 7
}*/