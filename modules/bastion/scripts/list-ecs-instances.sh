#!/bin/bash
# ECS 클러스터의 EC2 인스턴스 목록 조회 스크립트
CLUSTER_NAME="${1:-terraform-zero9905-ecs-cluster}"
REGION="${2:-us-east-2}"

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