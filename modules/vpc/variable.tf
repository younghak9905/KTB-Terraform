# VPC CIDR 블록
variable "vpc_ip_range" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnet_public_az1" {
  description = "CIDR block for public subnet in AZ1"
  type        = string
}

variable "subnet_public_az2" {
  description = "CIDR block for public subnet in AZ2"
  type        = string
}

variable "subnet_service_az1" {
  description = "CIDR block for service subnet in AZ1"
  type        = string
  
}

variable "subnet_service_az2" {
  description = "CIDR block for service subnet in AZ2"
  type        = string
}

variable "subnet_db_az1" {
  description = "CIDR block for DB subnet in AZ1"
  type        = string
  
}

variable "subnet_db_az2" {
  description = "CIDR block for DB subnet in AZ2"
  type        = string
}

# 가용 영역 리스트
variable "az" {
  description = "List of availability zones"
  type        = list(string)
}

# 태그 정보
variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
}

# 스테이지 및 서비스명
variable "stage" {
  description = "Deployment stage (e.g., dev, prod)"
  type        = string
}

variable "servicename" {
  description = "Service name identifier"
  type        = string
}