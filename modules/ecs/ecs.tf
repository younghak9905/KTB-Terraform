resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}


resource "aws_launch_template" "ecs_instance_lt" {
  name_prefix   = "${var.cluster_name}-cluster"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name = var.key_name
  user_data = base64encode(templatefile("${path.module}/scripts/user_data.sh.tpl", {
  ecs_cluster_name = aws_ecs_cluster.this.name
}))
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  vpc_security_group_ids = [aws_security_group.sg_ecs[0].id]

  # 필요 시 추가 설정 (예: key_name, block_device_mappings 등) 추가
}

resource "aws_security_group" "sg_ecs" {
  count  = var.create_ecs ? 1 : 0
  name        = "sg_${var.cluster_name}_ecs"
  description = "Security group for ECS EC2 instances"
  vpc_id        = var.vpc_id

  ingress {
    from_port       = 80  # 컨테이너 포트 (예: Nginx, Spring Boot 등)
    to_port         = 80
    protocol        = "TCP"
    security_groups = [var.sg_alb_id] # ALB에서 오는 트래픽만 허용
  }

  ingress {
  from_port       = 8080
  to_port         = 8080
  protocol        = "TCP"
  security_groups = [var.sg_alb_id]
}

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = [var.shared_vpc_cidr]  # Shared VPC에서 오는 SSH 트래픽 허용
    description = "SSH access from Shared VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # 인터넷 접근 허용 (필요시 변경)
  }

  tags = merge(var.tags, { "Name" = "sg-${var.stage}-${var.cluster_name}-ecs" })
}

resource "aws_autoscaling_group" "ecs_instances" {
  vpc_zone_identifier  = var.subnet_ids
  desired_capacity     = var.desired_capacity
  min_size             = var.min_size
  max_size             = var.max_size

  launch_template {
    id      = aws_launch_template.ecs_instance_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.instance_name
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

#ecs task

resource "aws_ecs_task_definition" "task" {
  family                   = var.task_family
  network_mode             = var.task_network_mode  # 예: "bridge" 또는 "awsvpc"
  container_definitions    = var.container_definitions
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  tags = var.tags
}

resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.service_desired_count
  launch_type     = "EC2"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  # ALB 연동이 필요한 경우 load_balancer 블록을 추가하세요.
   load_balancer {
     target_group_arn = var.alb_target_group_arn
     container_name   = var.container_name
     container_port   = var.container_port
   }

  # ECS 서비스가 ASG와 함께 작동하도록 설정
  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  # 중요: ALB 대상 그룹 등록을 위한 IAM 역할 설정
  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_policy_attachment
  ]
}





