variable "stage" {
  type = string
}

variable "servicename" {
  type = string
}


variable "cluster_name" {
  description = "Name of the ECS Cluster"
  type        = string
}

variable "ecs_instance_role_name" {
  description = "IAM Role name for ECS container instances"
  type        = string
  default     = "ecsInstanceRole"
}

variable "ecs_instance_profile_name" {
  description = "IAM Instance Profile name for ECS container instances"
  type        = string
  default     = "ecsInstanceProfile"
}

variable "launch_template_name_prefix" {
  description = "Launch template name prefix for ECS container instances"
  type        = string
  default     = "ecs-launch-"
}

variable "ecs_ami_id" {
  description = "ECS Optimized AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for ECS container instances"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Key pair name for EC2 instances"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "User data script for EC2 instances"
  type        = string
  default     = ""
}

variable "instance_name" {
  description = "Instance name tag for ECS container instances"
  type        = string
  default     = "ecs-instance"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ECS container instances"
  type        = list(string)
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB Target Group from the ALB module"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB Listener from the ALB module"
  type        = string
}

variable "container_image" {
  description = "Container image"
  type        = string
  default = "nginx:latest"
}

variable "container_name" {
  description = "Container name"
  type        = string
  default = "nginx"
}

variable "container_port" {
  description = "Container port"
  type        = number
  default = 80
}
variable "sg_list" {
  description = "List of security group IDs"
  type        = list(string)
}


variable "create_ecs_sg" {
  type    = bool
  default = true
}

variable "create_ecs_instance_role" {
  type    = bool
  default = true

}
