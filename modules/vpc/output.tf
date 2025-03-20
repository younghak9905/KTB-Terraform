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

output "db_az1" {
  value = aws_subnet.db_az1.id
}

output "db_az2" {
  value = aws_subnet.db_az2.id
}

output "nat_ip" {
  value = concat(
    [aws_eip.nat_eip_1a.public_ip]
    #[aws_eip.nat_eip_1c.public_ip]
  )
}

output "nat_id" {
  value = [aws_nat_gateway.vpc_nat_1a.id]#, aws_nat_gateway.vpc_nat_1c.id]
}

output "private_route_table_ids" {
  value = [aws_route_table.rt_pri_1a.id, aws_route_table.rt_pri_1c.id]
}
