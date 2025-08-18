#!/bin/bash
set -e

echo "$(date): Starting application_start hook"

# 환경 변수 설정
CLUSTER_NAME="${CLUSTER_NAME:-stage-ktb-cluster}"
SERVICE_NAME="${SERVICE_NAME:-stage-ktb-backend}"
REGION="${AWS_DEFAULT_REGION:-us-east-2}"

echo "Updating ECS service: $SERVICE_NAME in cluster: $CLUSTER_NAME"

# ECS 서비스 업데이트 (새 태스크 정의로 강제 배포)
aws ecs update-service \
    --cluster "$CLUSTER_NAME" \
    --service "$SERVICE_NAME" \
    --force-new-deployment \
    --region "$REGION"

echo "$(date): ECS service update initiated"
echo "$(date): application_start hook completed"