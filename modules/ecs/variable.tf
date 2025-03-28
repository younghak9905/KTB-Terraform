variable "cluster_name" {
  description = "ECS 클러스터 이름"
  type        = string
}

variable "stage" {
  description = "환경 스테이지 (예: dev, prod)"
  type        = string
  default = "stage"
  
}

variable "instance_type" {
  description = "ECS 컨테이너 인스턴스의 EC2 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "ECS 최적화 AMI ID"
  type        = string
}

#variable "security_groups" {
#  description = "ECS 인스턴스에 적용할 보안 그룹 ID 목록"
#  type        = list(string)
#}

variable "subnet_ids" {
  description = "Auto Scaling Group에 사용할 서브넷 ID 목록"
  type        = list(string)
}

variable "associate_public_ip_address" {
  description = "퍼블릭 IP를 할당할지 여부"
  type        = bool
  default     = false
}

variable "desired_capacity" {
  description = "Auto Scaling Group의 원하는 용량"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Auto Scaling Group의 최소 인스턴스 수"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Auto Scaling Group의 최대 인스턴스 수"
  type        = number
  default     = 2
}

variable "instance_name" {
  description = "ECS 인스턴스에 부여할 Name 태그 값"
  type        = string
  default     = "ecs-instance"
}

# ECS Task 관련 변수
variable "task_family" {
  description = "ECS Task Definition의 패밀리 이름"
  type        = string
}

variable "task_network_mode" {
  description = "Task 정의의 네트워크 모드 (예: bridge, awsvpc)"
  type        = string
  default     = "bridge"
}

variable "container_definitions" {
  description = "ECS Task에 사용될 컨테이너 정의(JSON 형식)"
  type        = string
}

variable "task_execution_role_arn" {
  description = "ECS Task 실행을 위한 IAM 역할 ARN"
  type        = string
  default     = ""
}

variable "task_role_arn" {
  description = "ECS Task에서 사용할 IAM 역할 ARN"
  type        = string
  default     = ""
}

variable "task_cpu" {
  description = "ECS Task의 CPU 단위 (예: 256)"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "ECS Task의 메모리 (MB 단위)"
  type        = string
  default     = "512"
}

variable "service_name" {
  description = "ECS Service 이름"
  type        = string
}

variable "service_desired_count" {
  description = "ECS Service에서 실행할 Task의 원하는 개수"
  type        = number
  default     = 1
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB Target Group from the ALB module"
  type        = string
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

variable "create_ecs" {
  type    = bool
  default = true
  
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  
}

variable "sg_alb_id" {
  description = "value of the security group id"
  type = string
}

variable "key_name" {
  description = "key name"
  type = string
}

variable "shared_vpc_cidr" {
  description = "Shared VPC의 CIDR 블록"
  type        = string
  default     = "10.3.0.0/16"
}