#!/bin/bash
# 기본 시스템 업데이트 및 도구 설치
yum update -y
yum install -y wget net-tools jq awscli

# OpenVPN 설치 스크립트 복사
cat > /home/ec2-user/openvpn-install.sh << 'OPENVPNEOF'
${openvpn_script}
OPENVPNEOF

chmod +x /home/ec2-user/openvpn-install.sh
chown ec2-user:ec2-user /home/ec2-user/openvpn-install.sh

# ECS 인스턴스 조회 스크립트 복사
cat > /usr/local/bin/list-ecs-instances.sh << 'ECSEOF'
${ecs_script}
ECSEOF

chmod +x /usr/local/bin/list-ecs-instances.sh

# 안내 메시지 생성
cat > /home/ec2-user/README.txt << READMEEOF
=== OpenVPN 설치 안내 ===

1. 다음 명령어로 OpenVPN을 설치하세요:
   sudo bash openvpn-install.sh

2. 설치가 완료되면 client1.ovpn 파일이 생성됩니다.

3. 다음 명령어로 이 파일을 로컬 컴퓨터로 다운로드하세요:
   scp -i your-key.pem ec2-user@$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):/home/ec2-user/client1.ovpn .

4. OpenVPN Connect 앱에서 .ovpn 파일을 가져와 사용하세요.

=== ECS 인스턴스 조회 ===

다음 명령어로 ECS 클러스터의 EC2 인스턴스를 조회할 수 있습니다:
   /usr/local/bin/list-ecs-instances.sh [클러스터_이름] [리전]

예시:
   /usr/local/bin/list-ecs-instances.sh terraform-zero9905-ecs-cluster us-east-2
READMEEOF

chown ec2-user:ec2-user /home/ec2-user/README.txt

# 호스트 이름 설정
hostnamectl set-hostname bastion-${stage}-${servicename}