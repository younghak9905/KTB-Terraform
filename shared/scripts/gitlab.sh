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
#echo "GitLab 서비스 시작 중... (5분 대기)"
#sleep 300

# GitLab 서비스 시작 확인 함수
wait_for_gitlab() {
  echo "GitLab 서비스 시작 대기 중..."
  local gitlab_ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
  local max_attempts=30
  local attempt=1
  local delay=10
  
  # GitLab 헬스 체크 URL
  local health_url="http://${gitlab_ip}/-/health"
  
  while [ $attempt -le $max_attempts ]; do
    echo "헬스 체크 시도 ${attempt}/${max_attempts}..."
    
    # GitLab 헬스 엔드포인트 확인
    if curl -s -m 5 ${health_url} | grep -q "success"; then
      echo "GitLab 서비스가 준비되었습니다!"
      return 0
    fi
    
    # 대체 방법: GitLab 로그인 페이지 접근 가능 여부 확인
    if curl -s -m 5 -o /dev/null -w '%{http_code}' "http://${gitlab_ip}/users/sign_in" | grep -q "200"; then
      echo "GitLab 로그인 페이지가 준비되었습니다!"
      
      # 로그인 페이지가 로드되어도 추가로 30초 더 대기 (내부 서비스 완전 초기화용)
      echo "내부 서비스 초기화 대기 중... (30초)"
      sleep 30
      return 0
    fi
    
    # 대기 후 다시 시도
    echo "GitLab이 아직 준비되지 않았습니다. ${delay}초 후 다시 시도합니다..."
    sleep $delay
    attempt=$((attempt + 1))
  done
  
  echo "경고: GitLab 서비스 시작 시간이 초과되었습니다. 계속 진행하지만 문제가 발생할 수 있습니다."
  return 1
}

# GitLab 서비스 시작
cd /srv/gitlab
docker-compose up -d

# GitLab 서비스가 준비될 때까지 대기
wait_for_gitlab

# GitLab이 준비되면 Runner 등록 진행
GITLAB_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
echo "GitLab IP: $GITLAB_IP"

# GitLab Runner 등록 토큰 가져오기
# 여러 번 시도하여 토큰을 얻습니다 (서비스가 완전히 초기화되지 않은 경우를 대비)
MAX_TOKEN_ATTEMPTS=5
TOKEN_ATTEMPT=1
REGISTRATION_TOKEN=""

while [ $TOKEN_ATTEMPT -le $MAX_TOKEN_ATTEMPTS ] && [ -z "$REGISTRATION_TOKEN" ]; do
  echo "Runner 등록 토큰 얻기 시도 ${TOKEN_ATTEMPT}/${MAX_TOKEN_ATTEMPTS}..."
  REGISTRATION_TOKEN=$(docker exec -it gitlab gitlab-rails runner -e production "puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token" 2>/dev/null | grep -v "^$")
  
  if [ -n "$REGISTRATION_TOKEN" ]; then
    echo "Runner 등록 토큰을 성공적으로 얻었습니다!"
  else
    echo "Runner 등록 토큰을 얻지 못했습니다. 30초 후 다시 시도합니다..."
    sleep 30
    TOKEN_ATTEMPT=$((TOKEN_ATTEMPT + 1))
  fi
done

if [ -z "$REGISTRATION_TOKEN" ]; then
  echo "경고: Runner 등록 토큰을 얻지 못했습니다. Runner 등록을 건너뜁니다."
else
  echo "Runner 등록 토큰: $REGISTRATION_TOKEN"
  
  # GitLab Runner 컨테이너 시작 및 등록
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
    
  echo "GitLab Runner가 성공적으로 등록되었습니다!"
fi

echo "GitLab 및 GitLab Runner 설치가 완료되었습니다."
echo "GitLab 접속 주소: http://$GITLAB_IP"

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