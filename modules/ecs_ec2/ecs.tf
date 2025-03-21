resource "aws_ecs_cluster" "this" {
  name = "awse_ecs_${var.stage}_${var.servicename}"
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
  echo "ECS_CLUSTER=${aws_ecs_cluster.this.name}" >> /etc/ecs/ecs.config
  yum update -y
  amazon-linux-extras enable docker
  yum install -y docker
  service docker start
  systemctl enable docker
  start ecs
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
  name            = "ecs_service_${var.stage}_${var.servicename}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = 2
  launch_type     = "EC2"  # Fargate 대신 EC2 사용

   load_balancer {
    target_group_arn = var.alb_target_group_arn  # ✅ Target Group ARN을 참조하도록 변경
    container_name   = var.container_name        # ✅ 변수로 관리하여 유연성 확보
    container_port   = var.container_port        # ✅ 변수로 포트 관리
  }

}

resource "aws_security_group" "sg_ecs" {
  name        = "sg_${var.stage}_${var.servicename}_ecs"
  description = "Security group for ECS EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80  # 컨테이너 포트 (예: Nginx, Spring Boot 등)
    to_port         = 80
    protocol        = "TCP"
    security_groups = var.sg_list # ALB에서 오는 트래픽만 허용
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # 인터넷 접근 허용 (필요시 변경)
  }

  tags = merge(var.tags, { "Name" = "sg-${var.stage}-${var.servicename}-ecs" })
}
