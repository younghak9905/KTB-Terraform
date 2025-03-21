resource "aws_autoscaling_group" "this" {
  name                      = "aws_asg_${var.stage}-${var.servicename}"
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size

  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }

  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  tag {
    key                 = "Name"
    value               = var.instance_name
    propagate_at_launch = true
  }
  
}
