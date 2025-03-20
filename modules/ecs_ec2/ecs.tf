resource "aws_ecs_cluster" "this" {
  name = "awse-ecs-${var.stage}-${var.servicename}"
}

data "aws_iam_policy_document" "ecs_instance_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name               = var.ecs_instance_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_instance_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = var.ecs_instance_profile_name
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_launch_template" "ecs_launch_template" {
  name_prefix   = var.launch_template_name_prefix
  image_id      = var.ecs_ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    echo "Hello, World from Auto Scaling!" > /var/www/html/index.html
    systemctl start httpd
    systemctl enable httpd
  EOF
  )


  tag_specifications {
    resource_type = "instance"
    tags = merge({
      "Name" = var.instance_name
    }, var.tags)
  }
}


resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service-${var.stage}-${var.servicename}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = 2
  launch_type     = "EC2"  # Fargate 대신 EC2 사용

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.sg_ecs.id]
  }

  load_balancer {
    target_group_arn = var.alb_listener_arn
    container_name   = "nginx-container"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_lb_listener.lb-listener-80]
}

resource "aws_security_group" "sg_ecs" {
  name        = "sg-${var.stage}-${var.servicename}-ecs"
  description = "Security group for ECS EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80  # 컨테이너 포트 (예: Nginx, Spring Boot 등)
    to_port         = 80
    protocol        = "TCP"
    security_groups = [aws_security_group.sg_alb.id] # ALB에서 오는 트래픽만 허용
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # 인터넷 접근 허용 (필요시 변경)
  }

  tags = merge(var.tags, { "Name" = "sg-${var.stage}-${var.servicename}-ecs" })
}
