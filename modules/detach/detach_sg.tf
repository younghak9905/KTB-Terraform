data "aws_network_interfaces" "sg_attached_enis" {
  for_each = toset(var.security_group_ids)  # ✅ 여러 개의 SG 처리
  filter {
    name   = "group-id"
    values = [each.value]  # ✅ 특정 SG에 연결된 ENI만 필터링
  }
}

resource "aws_network_interface_sg_attachment" "detach_sg" {
  for_each = data.aws_network_interfaces.sg_attached_enis  # ✅ 각 SG에 대해 반복 실행

  security_group_id    = each.key  # ✅ SG ID
  network_interface_id = each.value.ids[0]  # ✅ 자동 조회된 ENI ID 사용

  lifecycle {
    create_before_destroy = true  # ✅ SG를 Detach한 후 삭제 진행
  }

  depends_on = [aws_security_group.target_sg]  # ✅ SG 삭제 이후 실행되도록 설정
}