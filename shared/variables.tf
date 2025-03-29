# shared/variables.tf

variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "us-east-2"
}

variable "tags" {
  description = "모든 리소스에 대한 추가 태그"
  type        = map(string)
  default     = {
    "Project"      = "architecture"
    "Owner"        = "zero"
    "Environment"  = "shared"
  }
}

# VPC 관련 변수
variable "vpc_cidr_block" {
  description = "VPC의 CIDR 블록"
  type        = string
  default = "aws_vpc.my_vpc.cidr_block"
}

variable "public_subnet_cidr" {
  description = "퍼블릭 서브넷의 CIDR 블록"
  type        = string
  default     = "aws_subnet.pub_subnet_1a.cidr_block"
}

variable "private_subnet_cidr" {
  description = "프라이빗 서브넷의 CIDR 블록"
  type        = string
  default     = "aws_subnet.prv_sub_1a.cidr_block"
}

variable "availability_zone" {
  description = "사용할 가용 영역"
  type        = string
  default     = "us-east-2a"
}

# Bastion 관련 변수
variable "bastion_ami_id" {
  description = "Bastion 인스턴스용 AMI ID (Amazon Linux 2 권장)"
  type        = string
  default     = "ami-05716d7e60b53d380"  # Amazon Linux 2
}

variable "bastion_instance_type" {
  description = "Bastion 인스턴스 유형"
  type        = string
  default     = "t3.micro"
}

variable "ssh_allow_cidr_blocks" {
  description = "Bastion에 SSH 접속 허용할 CIDR 블록 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # 프로덕션 환경에서는 특정 IP로 제한 권장
}

variable "admin_cidr_blocks" {
  description = "OpenVPN 관리 인터페이스에 접속 허용할 CIDR 블록 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # 프로덕션 환경에서는 특정 IP로 제한 권장
}
/*
# GitLab 관련 변수
variable "gitlab_ami_id" {
  description = "GitLab 인스턴스용 AMI ID (Amazon Linux 2 권장)"
  type        = string
  default     = "ami-05716d7e60b53d380"  # Amazon Linux 2
}

variable "gitlab_instance_type" {
  description = "GitLab 인스턴스 유형"
  type        = string
  default     = "t3.large"
}

# ALB 보안 그룹 ID (GitLab에 HTTP/HTTPS 접근을 위해)
variable "alb_security_group_id" {
  description = "ALB의 보안 그룹 ID"
  type        = string
  default     = ""  # 없으면 비워두세요
}*/

# 공통 변수
variable "key_name" {
  description = "EC2 인스턴스의 SSH 키 이름"
  type        = string
  default = "0317"
  #tfvars 파일에서 참조
}
/*
variable "kms_key_id" {
  description = "EBS 암호화를 위한 KMS 키 ID"
  type        = string
}*/