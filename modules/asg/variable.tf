
variable "stage" {
  type = string
}

variable "servicename" {
  type = string
}



variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "desired_capacity" {
  description = "Desired capacity of the ASG"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum size of the ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size of the ASG"
  type        = number
  default     = 3
}

variable "launch_template_id" {
  description = "Launch template ID for the ASG"
  type        = string
}

variable "launch_template_version" {
  description = "Launch template version for the ASG"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to attach the ASG"
  type        = list(string)
}

variable "health_check_type" {
  description = "Health check type (EC2 or ELB)"
  type        = string
  default     = "EC2"
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
}

variable "instance_name" {
  description = "Name tag for instances launched by the ASG"
  type        = string
  default     = "asg-instance"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
