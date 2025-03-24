variable "stage" {
  type = string
}

variable "servicename" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "internal" {
  type    = bool
  default = true
}

variable "public" {
  type    = bool
  default = false
}

variable "subnet_ids" {
  type = list(string)
}

variable "aws_s3_lb_logs_name" {
  type = string
}

variable "idle_timeout" {
  type    = string
  default = "60"
}

# 🔴 SSL 인증서는 현재 사용 안 하므로 선택 사항
variable "certificate_arn" {
  type    = string
  default = ""
}

variable "port" {
  type    = string
  default = "80"
}

variable "vpc_id" {
  type = string
}
/*
variable "instance_ids" {
  type = list(string)
}*/

variable "domain" {
  type    = string
  default = ""
}

variable "hostzone_id" {
  type    = string
  default = ""
}

variable "hc_path" {
  type    = string
  default = "/"
}

variable "hc_healthy_threshold" {
  type    = number
  default = 5
}

variable "hc_unhealthy_threshold" {
  type    = number
  default = 2
}

variable "sg_allow_comm_list" {
  type = list(string)
}

variable "target_type" {
  type    = string
  default = "instance"
}

variable "availability_zone" {
  type    = string
  default = ""
}

variable "create_alb" {
  type    = bool
  default = true

}

