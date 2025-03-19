# vpc/subnet관련 소스
# public subnet az1, 2
# service subnet az1, 2
# db subnet az1, 2
# igw
# nat
# routetable pub,pri
# routetable association

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

# # RDS Subnet Group 
# # Fowler - Merge이후 주석 삭제
# resource "aws_db_subnet_group" "db-subnet-group-gitlab" {
#   name                    = "aws-db-subnet-group-gitlab"
#   subnet_ids              = [aws_subnet.db-az1.id, aws_subnet.db-az2.id]
#   tags                    = merge(tomap({
#                             Name = "aws-db-subnet-group-gitlab"}), 
#                             var.tags)
# }

# # redis Subnet Group 
# # Fowler - Merge이후 주석 삭제
# resource "aws_elasticache_subnet_group" "redis-subnet-group-gitlab" {
#   name                    = "aws-redis-subnet-group-gitlab"
#   subnet_ids              = [aws_subnet.db-az1.id, aws_subnet.db-az2.id]
#   tags                    = merge(tomap({
#                             Name = "aws-redis-subnet-group-gitlab"}), 
#                             var.tags)
# }

# igw
resource "aws_internet_gateway" "vpc-igw" {
  vpc_id = aws_vpc.aws-vpc.id
  tags = merge(tomap({
         Name = "aws-igw-${var.stage}-${var.servicename}"}), 
        var.tags)
}

resource "aws_nat_gateway" "vpc-nat" {
  count         = length(var.subnet_service_list)  # NAT도 개수만큼 생성
  allocation_id = aws_eip.nat-eip[count.index].id
  subnet_id     = var.subnet_service_list[count.index]  # 서비스 서브넷 연결
  depends_on    = [aws_internet_gateway.vpc-igw]

  tags = merge(
    tomap({ Name = "aws-nat-${var.stage}-${var.servicename}-${count.index + 1}" }),
    var.tags
  )
}

resource "aws_nat_gateway" "vpc-nat" {
  count         = length(var.subnet_service_list)  # NAT도 개수만큼 생성
  allocation_id = aws_eip.nat-eip[count.index].id
  subnet_id     = var.subnet_service_list[count.index]  # 서비스 서브넷 연결
  depends_on    = [aws_internet_gateway.vpc-igw]

  tags = merge(
    tomap({ Name = "aws-nat-${var.stage}-${var.servicename}-${count.index + 1}" }),
    var.tags
  )
}

#routetable
resource "aws_route_table" "aws-rt-pub" {
  vpc_id = aws_vpc.aws-vpc.id
  tags = merge(tomap({
         Name = "aws-rt-${var.stage}-${var.servicename}-pub"}), 
        var.tags)
}

resource "aws_route" "route-to-igw" {
  route_table_id         = aws_route_table.aws-rt-pub.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.vpc-igw.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "aws-rt-pri" {
  count  = length(var.subnet_service_list)
  vpc_id = aws_vpc.aws-vpc.id

  tags = merge(
    tomap({ Name = "aws-rt-${var.stage}-${var.servicename}-pri-${count.index + 1}" }),
    var.tags
  )
}

resource "aws_route" "route-to-nat" {
  count                  = length(var.subnet_service_list)
  route_table_id         = aws_route_table.aws-rt-pri[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.vpc-nat[count.index].id
}

# DB 서브넷 전용 라우트 테이블 (인터넷 차단)
resource "aws_route_table" "aws-rt-db" {
  vpc_id = aws_vpc.main.id

  tags = merge(tomap({
         Name = "aws-rt-${var.stage}-${var.servicename}-db"}), 
        var.tags)
}

# DB 서브넷은 VPC 내부(local) 트래픽만 허용
resource "aws_route" "route-to-local" {
  route_table_id         = aws_route_table.aws-rt-db.id
  destination_cidr_block = var.vpc_ip_range  # 전체 VPC 범위만 허용
  gateway_id             = "local"
}

#routetable association
resource "aws_route_table_association" "public-az1" {
 subnet_id      = aws_subnet.public-az1.id
 route_table_id = aws_route_table.aws-rt-pub.id
}
resource "aws_route_table_association" "public-az2" {
 subnet_id      = aws_subnet.public-az2.id
 route_table_id = aws_route_table.aws-rt-pub.id
}

# 🔵 서비스 서브넷 - 개별 NAT 게이트웨이 사용 (각 NAT-GW에 연결)
resource "aws_route_table_association" "service" {
  count = length(var.subnet_service_list)

  subnet_id      = var.subnet_service_list[count.index]
  route_table_id = aws_route_table.aws-rt-pri[count.index].id
}

# 🟣 DB 서브넷 - 인터넷 연결 없이 내부 통신만 허용 (local route)
resource "aws_route_table_association" "db" {
  for_each = toset(var.subnet_db_list)

  subnet_id      = each.value
  route_table_id = aws_route_table.aws-rt-db.id
}
