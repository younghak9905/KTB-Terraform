output "db_az1" {
  value = aws_subnet.db_az1.id
}

output "db_az2" {
  value = aws_subnet.db_az2.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_az1" {
  value = aws_subnet.public_az1.id
}

output "public_az2" {
  value = aws_subnet.public_az2.id
}

output "service_az1" {
  value = aws_subnet.service_az1.id
}

output "service_az2" {
  value = aws_subnet.service_az2.id
}

output "nat_ip" {
  value = aws_eip.nat_eip[*].public_ip
}

output "nat_id" {
  value = aws_nat_gateway.vpc_nat[*].id
}

output "private_route_table_ids" {
  value = aws_route_table.rt_pri[*].id
}
