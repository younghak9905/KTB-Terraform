provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Project  = "architecture"
      Owner    = "zero"
    }
  }
}

variable "vpc_main_cidr" {
  description = "VPC main CIDR block"
  default     = "20.0.0.0/23"
}

variable "secondary_cidr" {
  default = "20.1.0.0/23"
}

# VPC 생성
resource "aws_vpc" "my_vpc" {
  cidr_block          = var.vpc_main_cidr
  instance_tenancy    = "default"
  enable_dns_support  = true

  tags = {
    Name = "VPC-DEV"
  }
}

# VPC 보조 CIDR 추가
resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.secondary_cidr
}

# 퍼블릭 서브넷 1
resource "aws_subnet" "pub_subnet_1a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.my_vpc.cidr_block, 2, 0)
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-1a"
  }
}

# 프라이빗 서브넷 1
resource "aws_subnet" "prv_sub_1a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.my_vpc.cidr_block, 2, 1)
  availability_zone = "us-east-2a"

  tags = {
    Name = "Private-Subnet-1a"
  }
}

# 프라이빗 서브넷 2
resource "aws_subnet" "prv_sub_2a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.my_vpc.cidr_block, 2, 2)
  availability_zone = "us-east-2a"

  tags = {
    Name = "Private-Subnet-2a"
  }
}

# 퍼블릭 서브넷 2 (보조 CIDR)
resource "aws_subnet" "pub_subnet_1c" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = cidrsubnet(var.secondary_cidr, 2, 0)
  availability_zone       = "us-east-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-2c"
  }
}

# 프라이빗 서브넷 2 (보조 CIDR)
resource "aws_subnet" "prv_sub_1c" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = cidrsubnet(var.secondary_cidr, 2, 1)
  availability_zone = "us-east-2c"

  tags = {
    Name = "Private-Subnet-1c"
  }
}

# 프라이빗 서브넷 2 (보조 CIDR)
resource "aws_subnet" "prv_sub_2c" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = cidrsubnet(var.secondary_cidr, 2, 2)
  availability_zone = "us-east-2c"

  tags = {
    Name = "Private-Subnet-2c"
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "Internet-Gateway"
  }
}

# 퍼블릭 라우트 테이블
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

# NAT Gateway를 위한 EIP
resource "aws_eip" "nat_eip1" {
  domain = "vpc"

  tags = {
    Name = "NAT-EIP-1"
  }
}

resource "aws_eip" "nat_eip2" {
  domain = "vpc"

  tags = {
    Name = "NAT-EIP-2"
  }
}

# NAT Gateway 생성
resource "aws_nat_gateway" "nat_gw_1" {
  allocation_id = aws_eip.nat_eip1.id
  subnet_id     = aws_subnet.pub_subnet_1a.id
  depends_on    = [aws_internet_gateway.my_igw]

  tags = {
    Name = "NAT-GW-1"
  }
}

resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.nat_eip2.id
  subnet_id     = aws_subnet.pub_subnet_1c.id
  depends_on    = [aws_internet_gateway.my_igw]

  tags = {
    Name = "NAT-GW-2"
  }
}

# 프라이빗 라우트 테이블 1
resource "aws_route_table" "prv_rt1" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_1.id
  }

  tags = {
    Name = "Private-Route-Table-1"
  }
}

# 프라이빗 라우트 테이블 2
resource "aws_route_table" "prv_rt2" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_2.id
  }

  tags = {
    Name = "Private-Route-Table-2"
  }
}

# 서브넷과 라우트 테이블 연결
resource "aws_route_table_association" "pub_subnet_1a_asso" {
  subnet_id      = aws_subnet.pub_subnet_1a.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "pub_subnet_1c_asso" {
  subnet_id      = aws_subnet.pub_subnet_1c.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "prv_subnet_1a_asso" {
  subnet_id      = aws_subnet.prv_sub_1a.id
  route_table_id = aws_route_table.prv_rt1.id
}

resource "aws_route_table_association" "prv_subnet_2a_asso" {
  subnet_id      = aws_subnet.prv_sub_2a.id
  route_table_id = aws_route_table.prv_rt1.id
}


