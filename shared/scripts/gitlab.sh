#!/bin/bash

# 로그 파일 설정
LOG_FILE="/var/log/gitlab-setup.log"
echo "$(date "+%Y-%m-%d %H:%M:%S") - GitLab 및 GitLab Runner 설치 시작" | tee -a ${LOG_FILE}


yum update -y 

# Docker 설치

yum install -y docker 
systemctl enable docker
systemctl start docker

# Docker Compose 설치
curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 
chmod +x /usr/local/bin/docker-compose 
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose 



# GitLab 로컬 설치
echo "$(date "+%Y-%m-%d %H:%M:%S") - GitLab 저장소 추가 중..." | tee -a ${LOG_FILE}
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | bash >> ${LOG_FILE} 2>&1

# GitLab 설치
GITLAB_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
echo "$(date "+%Y-%m-%d %H:%M:%S") - GitLab 설치 중 (IP: ${GITLAB_IP})..." | tee -a ${LOG_FILE}
EXTERNAL_URL="http://${GITLAB_IP}" yum install -y gitlab-ee >> ${LOG_FILE} 2>&1

# GitLab 구성 (비밀번호 설정)
echo "$(date "+%Y-%m-%d %H:%M:%S") - GitLab 초기 설정 중..." | tee -a ${LOG_FILE}
sudo gitlab-ctl reconfigure >> ${LOG_FILE} 2>&1

# GitLab root 사용자 비밀번호 설정
echo "$(date "+%Y-%m-%d %H:%M:%S") - root 사용자 비밀번호 설정 중..." | tee -a ${LOG_FILE}
echo "password123" > /tmp/gitlab_pwd.txt
echo "password123" >> /tmp/gitlab_pwd.txt
cat /tmp/gitlab_pwd.txt | sudo gitlab-rake "gitlab:password:reset[root]" >> ${LOG_FILE} 2>&1
rm -f /tmp/gitlab_pwd.txt

# GitLab 서비스 상태 확인 함수
wait_for_gitlab() {
  echo "$(date "+%Y-%m-%d %H:%M:%S") - GitLab 서비스 시작 대기 중..." | tee -a ${LOG_FILE}
  local max_attempts=30
  local attempt=1
  local delay=10
  
  # GitLab 헬스 체크 URL
  local health_url="http://${GITLAB_IP}/-/health"
  
  while [ $attempt -le $max_attempts ]; do
    echo "$(date "+%Y-%m-%d %H:%M:%S") - 헬스 체크 시도 ${attempt}/${max_attempts}..." | tee -a ${LOG_FILE}
    
    # GitLab 헬스 엔드포인트 확인
    local health_response=$(curl -s -m 5 ${health_url})
    echo "$(date "+%Y-%m-%d %H:%M:%S") - 헬스 체크 응답: ${health_response}" | tee -a ${LOG_FILE}
    
    if echo "${health_response}" | grep -q "success"; then
      echo "$(date "+%Y-%m-%d %H:%M:%S") - GitLab 서비스가 준비되었습니다!" | tee -a ${LOG_FILE}
      return 0
    fi
    
    # 대체 방법: GitLab 로그인 페이지 접근 가능 여부 확인
    local http_code=$(curl -s -m 5 -o /dev/null -w '%{http_code}' "http://${GITLAB_IP}/users/sign_in")
    echo "$(date "+%Y-%m-%d %H:%M:%S") - 로그인 페이지 HTTP 코드: ${http_code}" | tee -a ${LOG_FILE}
    
    if echo "${http_code}" | grep -q "200"; then
      echo "$(date "+%Y-%m-%d %H:%M:%S") - GitLab 로그인 페이지가 준비되었습니다!" | tee -a ${LOG_FILE}
      
      # 로그인 페이지가 로드되어도 추가로 30초 더 대기 (내부 서비스 완전 초기화용)
      echo "$(date "+%Y-%m-%d %H:%M:%S") - 내부 서비스 초기화 대기 중... (30초)" | tee -a ${LOG_FILE}
      sleep 30
      echo "$(date "+%Y-%m-%d %H:%M:%S") - 내부 서비스 초기화 대기 완료" | tee -a ${LOG_FILE}
      return 0
    fi
    
    # 대기 후 다시 시도
    echo "$(date "+%Y-%m-%d %H:%M:%S") - GitLab이 아직 준비되지 않았습니다. ${delay}초 후 다시 시도합니다..." | tee -a ${LOG_FILE}
    sleep $delay
    attempt=$((attempt + 1))
  done
  
  echo "$(date "+%Y-%m-%d %H:%M:%S") - 경고: GitLab 서비스 시작 시간이 초과되었습니다. 계속 진행하지만 문제가 발생할 수 있습니다." | tee -a ${LOG_FILE}
  return 1
}

# GitLab 서비스가 준비될 때까지 대기
wait_for_gitlab

# GitLab Runner Docker 설정
echo "$(date "+%Y-%m-%d %H:%M:%S") - GitLab Runner 디렉토리 생성 중..." | tee -a ${LOG_FILE}
mkdir -p /srv/gitlab-runner/config >> ${LOG_FILE} 2>&1

# GitLab Runner Docker Compose 파일 생성
echo "$(date "+%Y-%m-%d %H:%M:%S") - GitLab Runner Docker Compose 파일 생성 중..." | tee -a ${LOG_FILE}
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

# GitLab Runner 시작
echo "$(date "+%Y-%m-%d %H:%M:%S") - GitLab Runner 시작 중..." | tee -a ${LOG_FILE}
cd /srv/gitlab-runner
docker-compose up -d >> ${LOG_FILE} 2>&1

# GitLab Runner 등록 토큰 가져오기
echo "$(date "+%Y-%m-%d %H:%M:%S") - GitLab Runner 등록 토큰 가져오기 중..." | tee -a ${LOG_FILE}
MAX_TOKEN_ATTEMPTS=5
TOKEN_ATTEMPT=1
REGISTRATION_TOKEN=""

while [ $TOKEN_ATTEMPT -le $MAX_TOKEN_ATTEMPTS ] && [ -z "$REGISTRATION_TOKEN" ]; do
  echo "$(date "+%Y-%m-%d %H:%M:%S") - Runner 등록 토큰 얻기 시도 ${TOKEN_ATTEMPT}/${MAX_TOKEN_ATTEMPTS}..." | tee -a ${LOG_FILE}
  
  REGISTRATION_TOKEN=$(sudo gitlab-rails runner -e production "puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token" 2>/dev/null | grep -v "^$")
  
  if [ -n "$REGISTRATION_TOKEN" ]; then
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Runner 등록 토큰을 성공적으로 얻었습니다!" | tee -a ${LOG_FILE}
  else
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Runner 등록 토큰을 얻지 못했습니다. 30초 후 다시 시도합니다..." | tee -a ${LOG_FILE}
    sleep 30
    TOKEN_ATTEMPT=$((TOKEN_ATTEMPT + 1))
  fi
done

if [ -z "$REGISTRATION_TOKEN" ]; then
  echo "$(date "+%Y-%m-%d %H:%M:%S") - 경고: Runner 등록 토큰을 얻지 못했습니다. Runner 등록을 건너뜁니다." | tee -a ${LOG_FILE}
else
  echo "$(date "+%Y-%m-%d %H:%M:%S") - Runner 등록 토큰: ${REGISTRATION_TOKEN}" | tee -a ${LOG_FILE}
  
  # GitLab Runner 등록
  echo "$(date "+%Y-%m-%d %H:%M:%S") - GitLab Runner 등록 중..." | tee -a ${LOG_FILE}
  docker exec -i gitlab-runner gitlab-runner register \
    --non-interactive \
    --url "http://${GITLAB_IP}" \
    --registration-token "${REGISTRATION_TOKEN}" \
    --executor "docker" \
    --docker-image alpine:latest \
    --description "docker-runner" \
    --tag-list "docker,aws" \
    --run-untagged="true" \
    --docker-privileged="true" >> ${LOG_FILE} 2>&1
    
  echo "$(date "+%Y-%m-%d %H:%M:%S") - GitLab Runner가 성공적으로 등록되었습니다!" | tee -a ${LOG_FILE}
fi

# 설치 완료 메시지
echo "$(date "+%Y-%m-%d %H:%M:%S") - GitLab 및 GitLab Runner 설치가 완료되었습니다." | tee -a ${LOG_FILE}
echo "$(date "+%Y-%m-%d %H:%M:%S") - GitLab 접속 주소: http://${GITLAB_IP}" | tee -a ${LOG_FILE}
echo "$(date "+%Y-%m-%d %H:%M:%S") - 로그인 ID: root" | tee -a ${LOG_FILE}
echo "$(date "+%Y-%m-%d %H:%M:%S") - 비밀번호: password123" | tee -a ${LOG_FILE}

# 모든 사용자에게 설치 완료 메시지 표시
cat << EOF > /etc/motd
===================================================
 GitLab 및 GitLab Runner가 설치되었습니다.
 
 GitLab 접속 주소: http://${GITLAB_IP}
 로그인 ID: root
 비밀번호: password123
 
 설치 로그: ${LOG_FILE}
===================================================
EOF

echo "$(date "+%Y-%m-%d %H:%M:%S") - 설치 스크립트 종료" | tee -a ${LOG_FILE}