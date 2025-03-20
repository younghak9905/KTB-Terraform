# VPC 생성
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_ip_range
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    { Name = "vpc-${var.stage}-${var.servicename}" },
    var.tags
  )
}

# 퍼블릭 서브넷 1
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_public_az1
  availability_zone       = element(var.az, 0)
  map_public_ip_on_launch = true

  tags = merge(
    { Name = "subnet-public-az1-${var.stage}-${var.servicename}" },
    var.tags
  )
}

# 퍼블릭 서브넷 2
resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_public_az2
  availability_zone       = element(var.az, 1)
  map_public_ip_on_launch = true

  tags = merge(
    { Name = "subnet-public-az2-${var.stage}-${var.servicename}" },
    var.tags
  )
}

# 서비스 서브넷 1
resource "aws_subnet" "service_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_service_az1
  availability_zone = element(var.az, 0)

  tags = merge(
    { Name = "subnet-service-az1-${var.stage}-${var.servicename}" },
    var.tags
  )
}

# 서비스 서브넷 2
resource "aws_subnet" "service_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_service_az2
  availability_zone = element(var.az, 1)

  tags = merge(
    { Name = "subnet-service-az2-${var.stage}-${var.servicename}" },
    var.tags
  )
}

# DB 서브넷 1
resource "aws_subnet" "db_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_db_az1
  availability_zone = element(var.az, 0)

  tags = merge(
    { Name = "subnet-db-az1-${var.stage}-${var.servicename}" },
    var.tags
  )
}

# DB 서브넷 2
resource "aws_subnet" "db_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_db_az2
  availability_zone = element(var.az, 1)

  tags = merge(
    { Name = "subnet-db-az2-${var.stage}-${var.servicename}" },
    var.tags
  )
}

# 인터넷 게이트웨이 (IGW)
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    { Name = "aws-igw-${var.stage}-${var.servicename}" },
    var.tags
  )
}

# NAT 게이트웨이에 사용할 Elastic IP (EIP)
resource "aws_eip" "nat_eip" {
  count = length(var.subnet_service_list)
  vpc   = true
}

# NAT 게이트웨이 (각 서비스 서브넷에 생성)
resource "aws_nat_gateway" "vpc_nat" {
  count         = length(var.subnet_service_list)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = var.subnet_service_list[count.index]
  depends_on    = [aws_internet_gateway.vpc_igw]

  tags = merge(
    { Name = "aws-nat-${var.stage}-${var.servicename}-${count.index + 1}" },
    var.tags
  )
}

# 퍼블릭 라우트 테이블
resource "aws_route_table" "rt_pub" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    { Name = "aws-rt-${var.stage}-${var.servicename}-pub" },
    var.tags
  )
}

# 퍼블릭 라우트 테이블의 인터넷 게이트웨이 연결
resource "aws_route" "route_to_igw" {
  route_table_id         = aws_route_table.rt_pub.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_igw.id

  lifecycle {
    create_before_destroy = true
  }
}

# 서비스 서브넷 전용 프라이빗 라우트 테이블 (각각 생성)
resource "aws_route_table" "rt_pri" {
  count  = length(var.subnet_service_list)
  vpc_id = aws_vpc.main.id

  tags = merge(
    { Name = "aws-rt-${var.stage}-${var.servicename}-pri-${count.index + 1}" },
    var.tags
  )
}

# 프라이빗 라우트 테이블에서 NAT 게이트웨이 연결
resource "aws_route" "route_to_nat" {
  count                  = length(var.subnet_service_list)
  route_table_id         = aws_route_table.rt_pri[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.vpc_nat[count.index].id
}

# DB 서브넷 전용 라우트 테이블 (내부 통신만 허용)
resource "aws_route_table" "rt_db" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    { Name = "aws-rt-${var.stage}-${var.servicename}-db" },
    var.tags
  )
}

# DB 라우트 테이블에서 VPC 내부 통신만 허용하는 경로 설정
resource "aws_route" "route_to_local" {
  route_table_id         = aws_route_table.rt_db.id
  destination_cidr_block = var.vpc_ip_range
  gateway_id             = "local"
}

# 라우트 테이블 연결

# 퍼블릭 서브넷과 퍼블릭 라우트 테이블 연결
resource "aws_route_table_association" "assoc_public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.rt_pub.id
}

resource "aws_route_table_association" "assoc_public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.rt_pub.id
}

# 서비스 서브넷과 프라이빗 라우트 테이블 연결
resource "aws_route_table_association" "assoc_service" {
  count          = length(var.subnet_service_list)
  subnet_id      = var.subnet_service_list[count.index]
  route_table_id = aws_route_table.rt_pri[count.index].id
}

# DB 서브넷과 DB 라우트 테이블 연결
resource "aws_route_table_association" "assoc_db" {
  for_each      = toset(var.subnet_db_list)
  subnet_id     = each.value
  route_table_id = aws_route_table.rt_db.id
}
