# GitLab CI/CD 변수 설정 가이드

## 1. GitLab Admin 접속
- GitLab 서버 접속: `http://{GitLab-IP}`
- 로그인: root / password123

## 2. CI/CD Variables 설정
**경로**: Settings → CI/CD → Variables

### 필수 변수들:
```
AWS_ACCESS_KEY_ID          # GitLab Runner용 AWS 액세스 키
AWS_SECRET_ACCESS_KEY      # GitLab Runner용 AWS 시크릿 키 (Masked)
AWS_DEFAULT_REGION         # us-east-2
AWS_ACCOUNT_ID             # AWS 계정 ID
CODEDEPLOY_APP_NAME        # shared-ktb-app
CODEDEPLOY_DEPLOYMENT_GROUP # shared-ktb-dg
S3_BUCKET                  # shared-ktb-codedeploy-artifacts
```

### 환경별 변수:
```
# Stage 환경
CLUSTER_NAME_STAGE         # stage-ktb-cluster
SERVICE_NAME_STAGE         # stage-ktb-backend

# Production 환경
CLUSTER_NAME_PROD          # prod-ktb-cluster
SERVICE_NAME_PROD          # prod-ktb-backend
```

## 3. Runner 등록 확인
- Admin Area → Overview → Runners
- Docker executor 확인
- Privileged mode 활성화 확인

## 4. 프로젝트별 설정
각 백엔드 프로젝트에서:
1. `.gitlab-ci.yml` 파일 추가
2. `appspec.yml` 및 `scripts/` 디렉토리 추가
3. `Dockerfile` 확인

## 5. 테스트 배포
1. feature 브랜치 생성 및 푸시
2. Pipeline 실행 확인
3. CodeDeploy 콘솔에서 배포 상태 확인