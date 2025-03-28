#!/bin/bash

# 시스템 업데이트
yum update -y

# Docker 설치
yum install -y docker
systemctl enable docker
systemctl start docker

# Docker Compose 설치
curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# 필요한 디렉토리 생성
mkdir -p /srv/gitlab/config /srv/gitlab/logs /srv/gitlab/data
mkdir -p /srv/gitlab-runner/config

# GitLab Docker Compose 파일 생성
cat > /srv/gitlab/docker-compose.yml << 'EOL'
version: '3.6'
services:
  gitlab:
    container_name: gitlab
    image: 'gitlab/gitlab-ee:latest'
    restart: always
    hostname: 'gitlab.example.com'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.example.com'
        gitlab_rails['gitlab_shell_ssh_port'] = 2222
        # 기본 루트 비밀번호 설정
        gitlab_rails['initial_root_password'] = 'password123'
        # 기본 이메일 설정 비활성화
        gitlab_rails['gitlab_email_enabled'] = false
    ports:
      - '80:80'
      - '443:443'
      - '2222:22'
    volumes:
      - '/srv/gitlab/config:/etc/gitlab'
      - '/srv/gitlab/logs:/var/log/gitlab'
      - '/srv/gitlab/data:/var/opt/gitlab'
    shm_size: '256m'
EOL

# GitLab Runner Docker Compose 파일 생성
cat > /srv/gitlab-runner/docker-compose.yml << 'EOL'
version: '3.6'
services:
  gitlab-runner:
    container_name: gitlab-runner
    image: 'gitlab/gitlab-runner:latest'
    restart: always
    volumes:
      - '/srv/gitlab-runner/config:/etc/gitlab-runner'
      - '/var/run/docker.sock:/var/run/docker.sock'
EOL

# GitLab 컨테이너 시작
cd /srv/gitlab
docker-compose up -d

# GitLab이 시작될 때까지 대기 (약 3분)
echo "GitLab 서비스 시작 중... (5분 대기)"
sleep 300

# GitLab 접근 토큰 얻기
GITLAB_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
echo "GitLab IP: $GITLAB_IP"

# GitLab Runner 등록 토큰 가져오기
# 참고: 컨테이너 내에서 명령을 실행하기 위해 docker exec 사용
REGISTRATION_TOKEN=$(docker exec -it gitlab gitlab-rails runner -e production "puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token")
echo "Runner 등록 토큰: $REGISTRATION_TOKEN"

# GitLab Runner 컨테이너 시작
cd /srv/gitlab-runner
docker-compose up -d

# GitLab Runner 등록
docker exec -it gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "http://$GITLAB_IP" \
  --registration-token "$REGISTRATION_TOKEN" \
  --executor "docker" \
  --docker-image alpine:latest \
  --description "docker-runner" \
  --tag-list "docker,aws" \
  --run-untagged="true" \
  --docker-privileged="true"

echo "GitLab 및 GitLab Runner 설치 완료"
echo "GitLab 접속 주소: http://$GITLAB_IP"
echo "초기 사용자: root"
echo "초기 비밀번호: password123"