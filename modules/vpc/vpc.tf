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

resource "aws_subnet" "public-az1" {
  vpc_id                  = aws_vpc.aws-vpc.id
  cidr_block              = var.subnet_public_az1
  map_public_ip_on_launch = false
  availability_zone       = element(var.az, 0)
  tags = merge(tomap({
         Name = "aws-subnet-${var.stage}-${var.servicename}-pub-az1"}), 
        var.tags)
  depends_on = [
    aws_vpc.aws-vpc
  ]
}
resource "aws_subnet" "public-az2" {
  vpc_id                  = aws_vpc.aws-vpc.id
  cidr_block              = var.subnet_public_az2
  map_public_ip_on_launch = false
  availability_zone       = element(var.az, 1)
  tags = merge(tomap({
         Name = "aws-subnet-${var.stage}-${var.servicename}-pub-az2"}), 
        var.tags)
  depends_on = [
    aws_vpc.aws-vpc
  ]
}

resource "aws_subnet" "service-az1" {
  vpc_id                  = aws_vpc.aws-vpc.id
  cidr_block              = var.subnet_service_az1
  map_public_ip_on_launch = false
  availability_zone       = element(var.az, 0)
  tags = merge(tomap({
         Name = "aws-subnet-${var.stage}-${var.servicename}-svc-az1"}), 
        var.tags)
  depends_on = [
    aws_vpc.aws-vpc
  ]
}
resource "aws_subnet" "service-az2" {
  vpc_id                  = aws_vpc.aws-vpc.id
  cidr_block              = var.subnet_service_az2
  map_public_ip_on_launch = false
  availability_zone       = element(var.az, 1)
  tags = merge(tomap({
         Name = "aws-subnet-${var.stage}-${var.servicename}-svc-az2"}), 
        var.tags)
  depends_on = [
    aws_vpc.aws-vpc
  ]
}


resource "aws_subnet" "db-az1" {
  vpc_id                  = aws_vpc.aws-vpc.id
  cidr_block              = var.subnet_db_az1
  map_public_ip_on_launch = false
  availability_zone       = element(var.az, 0)
  tags = merge(tomap({
         Name = "aws-subnet-${var.stage}-${var.servicename}-db-az1"}), 
        var.tags)
  depends_on = [
    aws_vpc.aws-vpc
  ]
}

resource "aws_subnet" "db-az2" {
  vpc_id                  = aws_vpc.aws-vpc.id
  cidr_block              = var.subnet_db_az2
  map_public_ip_on_launch = false
  availability_zone       = element(var.az, 1)
  tags = merge(tomap({
         Name = "aws-subnet-${var.stage}-${var.servicename}-db-az2"}), 
        var.tags)
  depends_on = [
    aws_vpc.aws-vpc
  ]
}

# 인터넷 게이트웨이 (IGW)
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    { Name = "aws-igw-${var.stage}-${var.servicename}" },
    var.tags
  )
}

# EIP for NAT
resource "aws_eip" "nat-eip-1a" {
  vpc = "true"
  depends_on                = [aws_internet_gateway.vpc-igw]
  tags = merge(tomap({
         Name = "aws-eip-${var.stage}-${var.servicename}-nat"}), 
        var.tags)
}

# EIP for NAT
resource "aws_eip" "nat-eip-1c" {
  vpc = "true"
  depends_on                = [aws_internet_gateway.vpc-igw]
  tags = merge(tomap({
         Name = "aws-eip-${var.stage}-${var.servicename}-nat"}), 
        var.tags)
}

# NAT
resource "aws_nat_gateway" "vpc-nat-1a" {
  allocation_id = aws_eip.nat-eip-1a.id
  subnet_id     = aws_subnet.public-az1.id
  depends_on = [aws_internet_gateway.vpc-igw, 
                aws_eip.nat-eip]
  tags = merge(tomap({
         Name = "aws-nat-${var.stage}-${var.servicename}"}), 
        var.tags)    
}

# NAT
resource "aws_nat_gateway" "vpc-nat-1c" {
  allocation_id = aws_eip.nat-eip-1c.id
  subnet_id     = aws_subnet.public-az1.id
  depends_on = [aws_internet_gateway.vpc-igw, 
                aws_eip.nat-eip]
  tags = merge(tomap({
         Name = "aws-nat-${var.stage}-${var.servicename}"}), 
        var.tags)    
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
resource "aws_route_table" "rt_pri_1a" {
 vpc_id = aws_vpc.aws-vpc.id
  tags = merge(tomap({
         Name = "aws-rt-${var.stage}-${var.servicename}-pri"}), 
        var.tags)
}

# 서비스 서브넷 전용 프라이빗 라우트 테이블 (각각 생성)
resource "aws_route_table" "rt_pri_1c" {
 vpc_id = aws_vpc.aws-vpc.id
  tags = merge(tomap({
         Name = "aws-rt-${var.stage}-${var.servicename}-pri"}), 
        var.tags)
}

resource "aws_route" "route-to-nat_1a" {
  route_table_id         = aws_route_table.aws-rt-pri_1a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.vpc-nat-1a.id
}

resource "aws_route" "route-to-nat_1c" {
  route_table_id         = aws_route_table.aws-rt-pri_1c.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.vpc-nat-1c.id
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
resource "aws_route_table_association" "assoc_service_az1" {

  subnet_id      = aws_subnet.service-az1.id
  route_table_id = aws_route_table.rt_pri_1a.id
}

# 서비스 서브넷과 프라이빗 라우트 테이블 연결
resource "aws_route_table_association" "assoc_service_az2" {

  subnet_id      = aws_subnet.service-az2.id
  route_table_id = aws_route_table.rt_pri_1c.id
}

# DB 서브넷 전용 라우트 테이블과 DB 서브넷 1 연결
resource "aws_route_table_association" "db_az1_assoc" {
  subnet_id      = aws_subnet.db_az1.id
  route_table_id = aws_route_table.rt_db.id
}

# DB 서브넷 전용 라우트 테이블과 DB 서브넷 2 연결
resource "aws_route_table_association" "db_az2_assoc" {
  subnet_id      = aws_subnet.db_az2.id
  route_table_id = aws_route_table.rt_db.id
}