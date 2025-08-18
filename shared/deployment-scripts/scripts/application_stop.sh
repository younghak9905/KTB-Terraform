#!/bin/bash
set -e

echo "$(date): Starting application_stop hook"

# 기존 컨테이너 정리 (필요시)
echo "Cleaning up old containers..."

# 환경 변수 설정
CLUSTER_NAME="${CLUSTER_NAME:-stage-ktb-cluster}"
SERVICE_NAME="${SERVICE_NAME:-stage-ktb-backend}"
REGION="${AWS_DEFAULT_REGION:-us-east-2}"

echo "$(date): application_stop hook completed"