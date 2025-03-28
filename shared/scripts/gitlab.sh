#!/bin/bash

# 시스템 업데이트
yum update -y

# 필요한 패키지 설치
yum install -y curl policycoreutils openssh-server perl postfix

# GitLab 저장소 설정 및 설치
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | bash
GITLAB_EXTERNAL_URL="http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)" yum install -y gitlab-ee

# GitLab Runner 저장소 설정 및 설치
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | bash
yum install -y gitlab-runner

# GitLab 설정 (초기 Root 비밀번호 설정)
gitlab-rake "gitlab:password:reset[root]" 2>/dev/null <<EOF
password123
password123
EOF

# GitLab Runner 등록 (자동 등록 토큰 사용)
sleep 180  # GitLab이 시작될 때까지 대기
REGISTRATION_TOKEN=$(gitlab-rails runner -e production "puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token")

gitlab-runner register \
  --non-interactive \
  --url "http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)" \
  --registration-token "$REGISTRATION_TOKEN" \
  --executor "shell" \
  --description "shell-runner" \
  --tag-list "shell,aws" \
  --run-untagged="true"

# GitLab Runner 서비스 시작 및 활성화
systemctl enable gitlab-runner
systemctl start gitlab-runner

# GitLab 서비스 재시작
gitlab-ctl reconfigure