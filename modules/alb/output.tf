#output "sg_alb_to_tg_id" {
# value = aws_security_group.sg-alb-to-tg.id
#}
#output "alb_dns_name" {
#  value = aws_lb.alb.dns_name
#}
#output "alb_zone_id" {
#  value = aws_lb.alb.zone_id
#}

output "target_group_arn" {
  # 인스턴스 인덱스를 추가합니다.
  value = aws_lb_target_group.target-group[0].arn
}

output "listener_arn" {
  # 인스턴스 인덱스를 추가합니다.
  value = aws_lb_listener.lb-listener-80[0].arn
}

output "sg_alb_id" {
  description = "ALB Security Group ID"
  # 인스턴스 인덱스를 추가합니다.
  value       = aws_security_group.sg_alb[0].id
}