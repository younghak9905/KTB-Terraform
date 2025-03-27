variable "requester_vpc_id" {
  description = "요청자 VPC ID"
  type        = string
}

variable "accepter_vpc_id" {
  description = "수락자 VPC ID"
  type        = string
}

variable "requester_cidr_block" {
  description = "요청자 VPC CIDR 블록"
  type        = string
}

variable "accepter_cidr_block" {
  description = "수락자 VPC CIDR 블록"
  type        = string
}

variable "requester_route_table_ids" {
  description = "요청자 VPC의 라우팅 테이블 ID 목록"
  type        = list(string)
}

variable "accepter_route_table_ids" {
  description = "수락자 VPC의 라우팅 테이블 ID 목록"
  type        = list(string)
}

variable "auto_accept" {
  description = "피어링 연결을 자동으로 수락할지 여부"
  type        = bool
  default     = true
}

variable "requester_name" {
  description = "요청자 VPC 이름 (태그용)"
  type        = string
}

variable "accepter_name" {
  description = "수락자 VPC 이름 (태그용)"
  type        = string
}

variable "tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}