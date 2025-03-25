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
    { Name = "aws-sg-${var.stage}-${var.servicename}-bastion" },
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

  user_data = <<-EOF
    #!/bin/bash
    # 시스템 업데이트
    yum update -y
    yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    
    # 필요한 패키지 설치
    yum install -y wget net-tools jq awscli

    # OpenVPN Access Server 설치 준비
    # 실제 설치는 연결 후 수동으로 수행하거나, 스크립트를 확장하여 자동화할 수 있습니다.
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    sysctl -p


    # OpenVPN 설치 스크립트 복사
cat > /home/ec2-user/openvpn-install.sh << 'OPENVPNSCRIPT'
${file("${path.module}/scripts/openvpn-install.sh")}
OPENVPNSCRIPT

chmod +x /home/ec2-user/openvpn-install.sh
chown ec2-user:ec2-user /home/ec2-user/openvpn-install.sh

# 안내 메시지 생성
cat > /home/ec2-user/README.txt << EOF
=== OpenVPN 설치 안내 ===

1. 다음 명령어로 OpenVPN을 설치하세요:
   sudo bash openvpn-install.sh

2. 설치가 완료되면 client1.ovpn 파일이 생성됩니다.

3. 다음 명령어로 이 파일을 로컬 컴퓨터로 다운로드하세요:
   scp -i your-key.pem ec2-user@$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):/home/ec2-user/client1.ovpn .

4. OpenVPN Connect 앱에서 .ovpn 파일을 가져와 사용하세요.


chown ec2-user:ec2-user /home/ec2-user/README.txt

    
    # ECS 인스턴스 접속을 위한 SSH 설정
    echo "# EC2 인스턴스 접속 설정" >> /home/ec2-user/.ssh/config
    echo "Host 10.*" >> /home/ec2-user/.ssh/config
    echo "    User ec2-user" >> /home/ec2-user/.ssh/config
    echo "    IdentityFile ~/.ssh/id_rsa" >> /home/ec2-user/.ssh/config
    echo "    StrictHostKeyChecking no" >> /home/ec2-user/.ssh/config
    
    # 권한 설정
    chmod 600 /home/ec2-user/.ssh/config
    chown ec2-user:ec2-user /home/ec2-user/.ssh/config
    
    # AWS CLI 유틸리티 스크립트 생성
    cat > /usr/local/bin/list-ecs-instances.sh << 'SCRIPT'
#!/bin/bash
# ECS 클러스터의 EC2 인스턴스 목록 조회 스크립트
CLUSTER_NAME="$${1:-terraform-zero9905-ecs-cluster}"
REGION="$${2:-us-east-2}"

echo "ECS 클러스터 '$CLUSTER_NAME'의 컨테이너 인스턴스 조회 중..."
CONTAINER_INSTANCES=$(aws ecs list-container-instances --cluster $CLUSTER_NAME --region $REGION | jq -r '.containerInstanceArns[]')

if [ -z "$CONTAINER_INSTANCES" ]; then
  echo "컨테이너 인스턴스를 찾을 수 없습니다."
  exit 1
fi

echo "컨테이너 인스턴스 목록:"
for INSTANCE_ARN in $CONTAINER_INSTANCES; do
  EC2_INSTANCE=$(aws ecs describe-container-instances --cluster $CLUSTER_NAME --container-instances $INSTANCE_ARN --region $REGION | jq -r '.containerInstances[].ec2InstanceId')
  EC2_INFO=$(aws ec2 describe-instances --instance-ids $EC2_INSTANCE --region $REGION)
  PRIVATE_IP=$(echo $EC2_INFO | jq -r '.Reservations[].Instances[].PrivateIpAddress')
  INSTANCE_TYPE=$(echo $EC2_INFO | jq -r '.Reservations[].Instances[].InstanceType')
  STATUS=$(echo $EC2_INFO | jq -r '.Reservations[].Instances[].State.Name')
  
  echo "- 인스턴스 ID: $EC2_INSTANCE"
  echo "  Private IP: $PRIVATE_IP"
  echo "  유형: $INSTANCE_TYPE"
  echo "  상태: $STATUS"
  echo ""
done
SCRIPT

    chmod +x /usr/local/bin/list-ecs-instances.sh
    
    # 호스트 이름 설정
    hostnamectl set-hostname bastion-${var.stage}-${var.servicename}
  EOF

  tags = merge(
    { Name = "aws-ec2-${var.stage}-${var.servicename}-bastion" },
    var.tags
  )

  volume_tags = merge(
    { Name = "aws-ebs-${var.stage}-${var.servicename}-bastion" },
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
    { Name = "aws-eip-${var.stage}-${var.servicename}-bastion" },
    var.tags
  )
}


