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
  map_public_ip_on_launch = false
  availability_zone       = element(var.az, 0)
  tags = merge(
    { Name = "aws_subnet_${var.stage}_${var.servicename}_pub_az1" },
    var.tags
  )
  depends_on = [aws_vpc.main]
}

# 퍼블릭 서브넷 2
resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_public_az2
  map_public_ip_on_launch = false
  availability_zone       = element(var.az, 1)
  tags = merge(
    { Name = "aws_subnet_${var.stage}_${var.servicename}_pub_az2" },
    var.tags
  )
  depends_on = [aws_vpc.main]
}

# 서비스 서브넷 1
resource "aws_subnet" "service_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_service_az1
  map_public_ip_on_launch = false
  availability_zone       = element(var.az, 0)
  tags = merge(
    { Name = "aws_subnet_${var.stage}_${var.servicename}_svc_az1" },
    var.tags
  )
  depends_on = [aws_vpc.main]
}

# 서비스 서브넷 2
resource "aws_subnet" "service_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_service_az2
  map_public_ip_on_launch = false
  availability_zone       = element(var.az, 1)
  tags = merge(
    { Name = "aws_subnet_${var.stage}_${var.servicename}_svc_az2" },
    var.tags
  )
  depends_on = [aws_vpc.main]
}

# DB 서브넷 1
resource "aws_subnet" "db_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_db_az1
  map_public_ip_on_launch = false
  availability_zone       = element(var.az, 0)
  tags = merge(
    { Name = "aws_subnet_${var.stage}_${var.servicename}_db_az1" },
    var.tags
  )
  depends_on = [aws_vpc.main]
}

# DB 서브넷 2
resource "aws_subnet" "db_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_db_az2
  map_public_ip_on_launch = false
  availability_zone       = element(var.az, 1)
  tags = merge(
    { Name = "aws_subnet_${var.stage}_${var.servicename}_db_az2" },
    var.tags
  )
  depends_on = [aws_vpc.main]
}

# 인터넷 게이트웨이 (IGW)
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    { Name = "aws_igw_${var.stage}_${var.servicename}" },
    var.tags
  )
}

# NAT 게이트웨이용 EIP - 1a
resource "aws_eip" "nat_eip_1a" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.vpc_igw]
  tags = merge(
    { Name = "aws_eip_${var.stage}_${var.servicename}_nat_1a" },
    var.tags
  )
}

# NAT 게이트웨이용 EIP - 1c
#resource "aws_eip" "nat_eip_1c" {
#  domain     = "vpc"
#  depends_on = [aws_internet_gateway.vpc_igw]
#  tags = merge(
#    { Name = "aws_eip_${var.stage}_${var.servicename}_nat_1c" },
#    var.tags
#  )
#}

# NAT 게이트웨이 - 1a (public_az1에 생성)
resource "aws_nat_gateway" "vpc_nat_1a" {
  allocation_id = aws_eip.nat_eip_1a.id
  subnet_id     = aws_subnet.public_az1.id
  depends_on    = [aws_internet_gateway.vpc_igw, aws_eip.nat_eip_1a]
  tags = merge(
    { Name = "aws_nat_${var.stage}_${var.servicename}_1a" },
    var.tags
  )
}

# NAT 게이트웨이 - 1c (public_az2에 생성)
#resource "aws_nat_gateway" "vpc_nat_1c" {
#  allocation_id = aws_eip.nat_eip_1c.id
#  subnet_id     = aws_subnet.public_az2.id
#depends_on    = [aws_internet_gateway.vpc_igw, aws_eip.nat_eip_1c]
#  tags = merge(
#    { Name = "aws_nat_${var.stage}_${var.servicename}_1c" },
#    var.tags
#  )
#}

# 퍼블릭 라우트 테이블
resource "aws_route_table" "rt_pub" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    { Name = "aws_rt_${var.stage}_${var.servicename}_pub" },
    var.tags
  )
}

# 퍼블릭 라우트 테이블의 IGW 연결
resource "aws_route" "route_to_igw" {
  route_table_id         = aws_route_table.rt_pub.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_igw.id

  lifecycle {
    create_before_destroy = false
  }
}

# 서비스 서브넷용 프라이빗 라우트 테이블 - 1a
resource "aws_route_table" "rt_pri_1a" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    { Name = "aws_rt_${var.stage}_${var.servicename}_pri_1a" },
    var.tags
  )
}

# 서비스 서브넷용 프라이빗 라우트 테이블 - 1c
resource "aws_route_table" "rt_pri_1c" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    { Name = "aws_rt_${var.stage}_${var.servicename}_pri_1c" },
    var.tags
  )
}

# 프라이빗 라우트 테이블에서 NAT 게이트웨이 연결 - 1a
resource "aws_route" "route_to_nat_1a" {
  route_table_id         = aws_route_table.rt_pri_1a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.vpc_nat_1a.id
}

# 프라이빗 라우트 테이블에서 NAT 게이트웨이 연결 - 1c
#resource "aws_route" "route_to_nat_1c" {
#  route_table_id         = aws_route_table.rt_pri_1c.id
#  destination_cidr_block = "0.0.0.0/0"
#  nat_gateway_id         = aws_nat_gateway.vpc_nat_1c.id
#}

# DB 서브넷 전용 라우트 테이블 (내부 통신만 허용)
resource "aws_route_table" "rt_db" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    { Name = "aws_rt_${var.stage}_${var.servicename}_db" },
    var.tags
  )
}

# 라우트 테이블 연결

resource "aws_route_table_association" "assoc_public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.rt_pub.id
}

resource "aws_route_table_association" "assoc_public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.rt_pub.id
}

resource "aws_route_table_association" "assoc_service_az1" {
  subnet_id      = aws_subnet.service_az1.id
  route_table_id = aws_route_table.rt_pri_1a.id
}

resource "aws_route_table_association" "assoc_service_az2" {
  subnet_id      = aws_subnet.service_az2.id
  route_table_id = aws_route_table.rt_pri_1a.id
}


resource "aws_route_table_association" "assoc_db_az1" {
  subnet_id      = aws_subnet.db_az1.id
  route_table_id = aws_route_table.rt_db.id
}

resource "aws_route_table_association" "assoc_db_az2" {
  subnet_id      = aws_subnet.db_az2.id
  route_table_id = aws_route_table.rt_db.id
}