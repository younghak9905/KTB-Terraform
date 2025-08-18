#!/bin/bash
set -e

echo "$(date): Starting validate_service hook"

# 환경 변수 설정
CLUSTER_NAME="${CLUSTER_NAME:-stage-ktb-cluster}"
SERVICE_NAME="${SERVICE_NAME:-stage-ktb-backend}"
REGION="${AWS_DEFAULT_REGION:-us-east-2}"

# 서비스 상태 확인
echo "Validating ECS service deployment..."

# 최대 10분 대기
MAX_ATTEMPTS=60
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: Checking service status..."
    
    SERVICE_STATUS=$(aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --region "$REGION" \
        --query 'services[0].deployments[?status==`PRIMARY`].runningCount' \
        --output text)
    
    DESIRED_COUNT=$(aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --region "$REGION" \
        --query 'services[0].desiredCount' \
        --output text)
    
    if [ "$SERVICE_STATUS" = "$DESIRED_COUNT" ] && [ "$SERVICE_STATUS" -gt 0 ]; then
        echo "$(date): Service validation successful! Running: $SERVICE_STATUS, Desired: $DESIRED_COUNT"
        exit 0
    fi
    
    echo "Service not ready yet. Running: $SERVICE_STATUS, Desired: $DESIRED_COUNT"
    sleep 10
    ATTEMPT=$((ATTEMPT + 1))
done

echo "$(date): Service validation failed after $MAX_ATTEMPTS attempts"
exit 1