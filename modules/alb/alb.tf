resource "aws_lb" "alb" {
  //name               = "aws_alb_${var.stage}-${var.servicename}"
  count = var.create_alb ? 1 : 0
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb[0].id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
  idle_timeout               = var.idle_timeout

  tags = merge(
    { Name = "aws-alb-${var.stage}-${var.servicename}" },
    var.tags
  )
}

# 🔵 HTTP 리스너 (80번 포트)
resource "aws_lb_listener" "lb-listener-80" {
  count = var.create_alb ? 1 : 0
  load_balancer_arn = aws_lb.alb[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Health OK"
      status_code  = "200"
    }
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

resource "aws_lb_listener_rule" "ecs_alb_listener_rule" {
  count        = var.create_alb ? 1 : 0
  listener_arn = aws_lb_listener.lb-listener-80[0].arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[0].arn
  }

  # condition {
  #   host_header {
  #     values = [var.domain_name]
  #   }
  # }G

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_lb_target_group" "target-group" {
  //name        = "aws_alb_tg_${var.stage}-${var.servicename}"
  count = var.create_alb ? 1 : 0
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
  depends_on = [aws_lb_listener.lb-listener-80]
}

#resource "aws_lb_target_group_attachment" "target-group-attachment" {
#  count = length(var.instance_ids)
#
#  target_group_arn = aws_lb_target_group.target-group.arn
#  target_id        = var.instance_ids[count.index]
#  port             = var.port
 # availability_zone = var.availability_zone
#
#  depends_on = [aws_lb_target_group.target-group]
#}



# ALB 보안 그룹
resource "aws_security_group" "sg_alb" {
 // name   = "aws-sg-${var.stage}-${var.servicename}-alb"
  count = var.create_alb ? 1 : 0
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

    lifecycle {
    create_before_destroy = true
    ignore_changes = [ingress]
  }
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