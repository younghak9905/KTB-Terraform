# provider 설정
provider "aws" {
  region = "us-east-2"
  
  default_tags {
    tags = {
      Project = "architecture"
      Owner   = "zero"
      Environment = "shared"
      ManagedBy = "terraform"
    }
  }
}

# 변수 정의
variable "vpc_main_cidr" {
  description = "VPC main CIDR block"
  default     = "10.0.0.0/23"
}

variable "stage" {
  description = "환경 스테이지 이름"
  type        = string
  default     = "shared"
}

variable "servicename" {
  description = "서비스 이름"
  type        = string
  default     = "terraform_zero9905"
}

# VPC 생성
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_main_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-${var.stage}-${var.servicename}"
  }
}

# 퍼블릭 서브넷
resource "aws_subnet" "pub_subnet_1a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.my_vpc.cidr_block, 1, 0)
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "aws-subnet-${var.stage}-${var.servicename}-public-2a"
  }
}

# 프라이빗 서브넷
resource "aws_subnet" "prv_sub_1a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.my_vpc.cidr_block, 1, 1)
  availability_zone = "us-east-2a"

  tags = {
    Name = "aws-subnet-${var.stage}-${var.servicename}-private-2a"
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "aws-igw-${var.stage}-${var.servicename}"
  }
}

# 퍼블릭 라우트 테이블
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "aws-rt-${var.stage}-${var.servicename}-public"
  }
}

# 퍼블릭 라우트 추가
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.pub_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

# NAT Gateway를 위한 EIP
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "aws-eip-${var.stage}-${var.servicename}-nat"
  }
  depends_on = [aws_internet_gateway.my_igw]
}

# NAT Gateway 생성
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.pub_subnet_1a.id

  tags = {
    Name = "aws-nat-${var.stage}-${var.servicename}"
  }
  depends_on = [aws_internet_gateway.my_igw]
}

# 프라이빗 라우트 테이블
resource "aws_route_table" "prv_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "aws-rt-${var.stage}-${var.servicename}-private"
  }
}

# 프라이빗 라우트 추가
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.prv_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# 서브넷과 라우트 테이블 연결
resource "aws_route_table_association" "pub_subnet_1a_asso" {
  subnet_id      = aws_subnet.pub_subnet_1a.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "prv_subnet_1a_asso" {
  subnet_id      = aws_subnet.prv_sub_1a.id
  route_table_id = aws_route_table.prv_rt.id
}

# 출력 정의
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.my_vpc.id
}

output "public_subnet_id" {
  description = "퍼블릭 서브넷 ID"
  value       = aws_subnet.pub_subnet_1a.id
}

output "private_subnet_id" {
  description = "프라이빗 서브넷 ID"
  value       = aws_subnet.prv_sub_1a.id
}