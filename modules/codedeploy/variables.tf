variable "stage" {
  description = "Environment stage"
  type        = string
}

variable "servicename" {
  description = "Service name"
  type        = string
}

variable "compute_platform" {
  description = "Compute platform for CodeDeploy (ECS or Server)"
  type        = string
  default     = "ECS"
  validation {
    condition     = contains(["ECS", "Server"], var.compute_platform)
    error_message = "Compute platform must be either 'ECS' or 'Server'."
  }
}

variable "deployment_config_name" {
  description = "CodeDeploy deployment configuration name"
  type        = string
  default     = "CodeDeployDefault.ECSAllAtOnce"
}

variable "ecs_cluster_name" {
  description = "ECS cluster name for ECS deployments"
  type        = string
  default     = ""
}

variable "ecs_service_name" {
  description = "ECS service name for ECS deployments"
  type        = string
  default     = ""
}

variable "ec2_tag_filters" {
  description = "EC2 tag filters for Server deployments"
  type = list(object({
    key   = string
    type  = string
    value = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}