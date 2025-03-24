resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}


resource "aws_launch_configuration" "ecs_instance_lc" {
  name_prefix                = "${var.cluster_name}-"
  image_id                   = var.ami_id
  instance_type              = var.instance_type
  iam_instance_profile       = aws_iam_instance_profile.ecs_instance_profile.name
  security_groups            = var.security_groups
  associate_public_ip_address = var.associate_public_ip_address

  # EC2 인스턴스가 ECS 클러스터에 가입하도록 설정
  user_data = <<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs_instances" {
  launch_configuration = aws_launch_configuration.ecs_instance_lc.name
  vpc_zone_identifier  = var.subnet_ids
  desired_capacity     = var.desired_capacity
  min_size             = var.min_size
  max_size             = var.max_size

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

  depends_on = [aws_ecs_cluster.this]
}





