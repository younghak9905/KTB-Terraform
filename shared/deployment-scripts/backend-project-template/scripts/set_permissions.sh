#!/bin/bash
# 배포 스크립트 실행 권한 설정

chmod +x /opt/codedeploy-agent/deployment-root/scripts/before_install.sh
chmod +x /opt/codedeploy-agent/deployment-root/scripts/application_start.sh
chmod +x /opt/codedeploy-agent/deployment-root/scripts/application_stop.sh
chmod +x /opt/codedeploy-agent/deployment-root/scripts/validate_service.sh

echo "$(date): Script permissions set successfully"