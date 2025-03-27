#!/bin/bash
# ECS 관련 설정
echo "ECS_CLUSTER=${ecs_cluster_name}" >> /etc/ecs/ecs.config

# 시스템 업데이트 및 필요한 패키지 설치
yum update -y

# ECS 에이전트가 설치되어 있지 않다면 설치
if [ ! -d "/etc/ecs" ]; then
  # Amazon Linux 2 ECS 최적화 AMI가 아닌 경우에만 실행
  yum install -y amazon-ecs-init
  systemctl enable ecs
  systemctl start ecs
fi

# SSM 에이전트 설치
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Docker 서비스 확인 및 시작
systemctl enable docker
systemctl start docker