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
  value = aws_lb_target_group.target-group.arn
}

output "listener_arn" {
  value = aws_lb_listener.lb-listener-80.arn
}

output "sg_alb_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.sg_alb.id
}

output "create_alb" {
    description = "Whether to create an ALB"
    value       = var.create_alb
  
}