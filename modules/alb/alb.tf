resource "aws_lb" "alb" {
  name               = "aws-alb-${var.stage}-${var.servicename}"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg-alb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = true
  idle_timeout               = var.idle_timeout

  access_logs {
    bucket  = var.aws_s3_lb_logs_name
    prefix  = "aws-alb-${var.stage}-${var.servicename}"
    enabled = true
  }

  tags = merge(
    { Name = "aws-alb-${var.stage}-${var.servicename}" },
    var.tags
  )
}

# 🔵 HTTP 리스너 (80번 포트)
resource "aws_lb_listener" "lb-listener-80" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }

  tags = var.tags
}

# 🔴 HTTPS 리스너 (443번 포트) - 현재 사용하지 않으므로 주석 처리
# resource "aws_lb_listener" "lb-listener-443" {
#   load_balancer_arn = aws_lb.alb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = var.certificate_arn
# 
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.target-group.arn
#   }
#   tags = var.tags
#   depends_on = [aws_lb_target_group.target-group]
# }

resource "aws_lb_target_group" "target-group" {
  name        = "aws-alb-tg-${var.stage}-${var.servicename}"
  port        = var.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = var.target_type

  health_check {
    path                = var.hc_path
    healthy_threshold   = var.hc_healthy_threshold
    unhealthy_threshold = var.hc_unhealthy_threshold
    matcher             = "200,301,302"
    interval            = 15
    timeout             = 3

  }

  tags = merge(
    { Name = "aws-alb-tg-${var.stage}-${var.servicename}" },
    var.tags
  )
}

resource "aws_lb_target_group_attachment" "target-group-attachment" {
  count = length(var.instance_ids)

  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = var.instance_ids[count.index]
  port             = var.port
  availability_zone = var.availability_zone

  depends_on = [aws_lb_target_group.target-group]
}



# ALB 보안 그룹
resource "aws_security_group" "sg-alb" {
  name   = "aws-sg-${var.stage}-${var.servicename}-alb"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = var.sg_allow_comm_list
    description = "Allow HTTP traffic"
  }

  # 🔴 HTTPS 포트(443)는 현재 주석 처리
  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "TCP"
  #   cidr_blocks = var.sg_allow_comm_list
  #   description = "Allow HTTPS traffic"
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    { Name = "aws-sg-${var.stage}-${var.servicename}-alb" },
    var.tags
  )
}

#resource "aws_route53_record" "alb-record" {
#  count = var.domain != "" ? 1 : 0
#
#  zone_id = var.hostzone_id
#  name    = "${var.stage}-${var.servicename}.${var.domain}"
#  type    = "A"#
#
#  alias {
#    name                   = aws_lb.alb.dns_name
#    zone_id                = aws_lb.alb.zone_id
#    evaluate_target_health = true
#  }
#}