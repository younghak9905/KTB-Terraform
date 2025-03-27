output "vpc_peering_id" {
  description = "VPC 피어링 연결 ID"
  value       = aws_vpc_peering_connection.peer.id
}

output "vpc_peering_status" {
  description = "VPC 피어링 연결 상태"
  value       = aws_vpc_peering_connection.peer.accept_status
}