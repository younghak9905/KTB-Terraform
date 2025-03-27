#!/bin/bash

## Configure cluster name using the template variable ${ecs_cluster_name}

echo ECS_CLUSTER='${ecs_cluster_name}' >> /etc/ecs/ecs.config

yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent