variable "region" {
  type = string
  default = "us-east-2"
}
variable "stage" {
  type = string
  default = "stage"
}
variable "servicename" {
  type = string
  default = "terraform_zero9905"
}
variable "tags" {
  type = map(string)
  default = {
    "Project"      = "architecture"
    "Owner"        = "zero"
    "Environment"  = "dev"
  }
}

#VPC
variable "az" {
  type = list(any)
  default = [ "us-east-2a", "us-east-2c" ]
}
variable "vpc_ip_range" {
  type = string
  default = "10.2.92.0/24"
}

variable "subnet_public_az1" {
  type = string
  default = "10.2.92.0/27"
}
variable "subnet_public_az2" {
  type = string
  default = "10.2.92.32/27"
}

variable "subnet_service_az1" {
  type = string
  default = "10.2.92.64/26"
}
variable "subnet_service_az2" {
  type = string
  default = "10.2.92.128/26"
}

variable "subnet_db_az1" {
  type = string
  default = "10.2.92.192/27"
}

variable "subnet_db_az2" {
  type = string
  default = "10.2.92.224/27"
}
# variable "create_tgw" {
#   type = bool
#   default = false
# }
# variable "ext_vpc_route" {
#   type = any
# }
# variable "security_attachments" {
#   type = any
# }
# variable "security_attachments_propagation" {
#   type = any
# }
# variable "tgw_sharing_accounts" {
#   type = map
# }


##Instance
variable "ami"{
  type = string
  default = "ami-0d0f28110d16ee7d6"
}
variable "instance_type" {
  type = string
  default = "t3.micro"
}
variable "instance_ebs_size" {
  type = number
  default = 20
}
variable "instance_ebs_volume" {
  type = string
  default = "gp3"
}

# variable "instance_user_data" {
#   type = string
# }
# variable "redis_endpoints" {
#   type = list
# }

##RDS
variable "rds_dbname" {
  type = string
  default = "zero9905"
}
variable "rds_instance_count" {
  type = string
  default = "2"
}
variable "sg_allow_ingress_list_aurora"{
  type = list
  default = ["10.2.92.64/26", "10.2.92.128/26", "10.2.92.18/32"]
}
variable "associate_public_ip_address" {
  type = bool
  default = true
}

#data "aws_kms_key" "rds_kms" {
#  key_id = "alias/my-rds-kms-key"
#}

#ata "aws_kms_key" "ebs_kms" {
#  key_id = "alias/my-ebs-kms-key"
#}

#variable "rds_kms_arn" {
#  default = data.aws_kms_key.rds_kms.arn
#}

#variable "ebs_kms_key_id" {
#  default = data.aws_kms_key.ebs_kms.arn
#}



##ALB
variable "aws_s3_lb_logs_name" {
  type = string
  default = "zero9905-alb-logs"
}

variable "domain" {
  type    = string
  default = ""
}

variable "hostzone_id" {
  type    = string
  default = ""
}

variable "create_ec2" {
  type = bool
  default = true
}

variable "create_ecs" {
  type = bool
  default = true
}


# 공통 변수
variable "key_name" {
  description = "EC2 인스턴스의 SSH 키 이름"
  type        = string
  default = "0317"
  #tfvars 파일에서 참조
}