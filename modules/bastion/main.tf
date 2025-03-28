# shared/modules/bastion/main.tf
# OpenVPN용 Bastion 서버 모듈

# Bastion 보안 그룹
resource "aws_security_group" "bastion_sg" {
  name        = "aws-sg-${var.stage}-${var.servicename}-bastion"
  description = "Security group for Bastion server (OpenVPN)"
  vpc_id      = var.vpc_id

  # SSH 접속 허용
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allow_cidr_blocks
    description = "SSH access"
  }

  # OpenVPN (UDP) 접속 허용
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "OpenVPN UDP"
  }

  # OpenVPN (TCP) 접속 허용
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "OpenVPN TCP"
  }

  # OpenVPN 관리 웹 인터페이스
  ingress {
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
    description = "OpenVPN Admin Web Interface"
  }

  # 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  # VPC 내부 통신 허용 (ECS 인스턴스 등 접근을 위함)
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow SSH to VPC resources"
  }

  tags = merge(
    { Name = "sg-${var.stage}-${var.servicename}-bastion" },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Bastion EC2 인스턴스
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = var.instance_profile

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
 # kms_key_id            = var.kms_key_id
  }

   # 이 방식으로 변경: 인라인 스크립트 대신 템플릿 파일 사용
  user_data = templatefile("${path.module}/scripts/user_data.sh.tpl", {
    stage = var.stage,
    servicename = var.servicename,
    openvpn_script = file("${path.module}/scripts/openvpn-install.sh"),
    ecs_script = file("${path.module}/scripts/list-ecs-instances.sh")
  })

  tags = merge(
    { Name = "ec2-${var.stage}-${var.servicename}-bastion" },
    var.tags
  )

  volume_tags = merge(
    { Name = "ebs-${var.stage}-${var.servicename}-bastion" },
    var.tags
  )

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# EIP for Bastion
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"
  
  tags = merge(
    { Name = "eip-${var.stage}-${var.servicename}-bastion" },
    var.tags
  )
}


