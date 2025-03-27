resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = var.requester_vpc_id
  peer_vpc_id   = var.accepter_vpc_id
  auto_accept   = var.auto_accept

  tags = merge(
    {
      Name = "vpc-peering-${var.requester_name}-to-${var.accepter_name}"
    },
    var.tags
  )
}

# 요청자 VPC 라우팅 테이블에 수락자 VPC CIDR로 향하는 트래픽을 피어링 연결로 라우팅
resource "aws_route" "requester_to_accepter" {
  for_each = {
    for idx, rtb_id in var.requester_route_table_ids : rtb_id => var.accepter_cidr_block
    if var.enable_route_creation # 선택적으로 라우트 생성을 제어하는 변수
  }
  
  route_table_id            = each.key
  destination_cidr_block    = each.value
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  
  # 라우트가 이미 존재할 경우 무시
  lifecycle {
    ignore_changes = [route_table_id, destination_cidr_block]
  }
}

# 수락자 VPC 라우팅 테이블에 요청자 VPC CIDR로 향하는 트래픽을 피어링 연결로 라우팅
resource "aws_route" "accepter_to_requester" {
  for_each = {
    for idx, rtb_id in var.accepter_route_table_ids : rtb_id => var.requester_cidr_block
    if var.enable_route_creation # 선택적으로 라우트 생성을 제어하는 변수
  }
  
  route_table_id            = each.key
  destination_cidr_block    = each.value
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  
  # 라우트가 이미 존재할 경우 무시
  lifecycle {
    ignore_changes = [route_table_id, destination_cidr_block]
  }
}