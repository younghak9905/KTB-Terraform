# 🌐 Terraform Cloud 설정 가이드

## 1. Terraform Cloud 계정 생성
1. https://app.terraform.io 접속
2. 계정 생성 또는 로그인
3. Organization 생성: `ktb-terraform`

## 2. Workspace 생성
1. **New Workspace** 클릭
2. **Version control workflow** 선택
3. GitHub 연결 및 저장소 선택: `KTB-Terraform`
4. Workspace 이름: `shared-infrastructure`
5. **Advanced options**:
   - Working Directory: `shared`
   - Auto apply: 체크 해제 (수동 승인)

## 3. Environment Variables 설정
Workspace → Variables → Environment Variables:

```
AWS_ACCESS_KEY_ID          # Sensitive 체크
AWS_SECRET_ACCESS_KEY      # Sensitive 체크
AWS_DEFAULT_REGION         # us-east-2
```

## 4. Terraform Variables 설정
Workspace → Variables → Terraform Variables:

```
stage                      # "shared"
servicename               # "ktb"
vpc_main_cidr             # "10.0.0.0/23"
key_name                  # "0317"
```

## 5. GitHub Secrets 설정
GitHub Repository → Settings → Secrets and variables → Actions:

```
TF_API_TOKEN              # Terraform Cloud API Token
```

### API Token 생성 방법:
1. Terraform Cloud → User Settings → Tokens
2. **Create an API token** 클릭
3. Description: `GitHub Actions`
4. 생성된 토큰을 GitHub Secrets에 추가

## 6. 배포 프로세스
1. **GitHub에 코드 푸시**
2. **GitHub Actions 자동 실행**
3. **Terraform Cloud에서 Plan 확인**
4. **Terraform Cloud에서 Apply 승인**

## 7. Stage Workspace 생성
1. **New Workspace** 클릭
2. **Version control workflow** 선택
3. GitHub 연결 및 저장소 선택: `KTB-Terraform`
4. Workspace 이름: `stage-infrastructure`
5. **Advanced options**:
   - Working Directory: `terraform_stage`
   - Auto apply: 체크 해제 (수동 승인)

### Stage Environment Variables:
```
AWS_ACCESS_KEY_ID          # Sensitive 체크
AWS_SECRET_ACCESS_KEY      # Sensitive 체크
AWS_DEFAULT_REGION         # us-east-2
```

### Stage Terraform Variables:
```
stage                      # "stage"
servicename               # "ktb"
vpc_ip_range              # "10.3.92.0/24"
key_name                  # "0317"
service_port              # 3000
```

## 8. 팀 협업 설정
1. Workspace → Settings → Team Access
2. 팀원 초대 및 권한 설정:
   - **Plan**: 개발자
   - **Write**: 시니어 개발자
   - **Admin**: DevOps 엔지니어

## 9. 알림 설정
1. Workspace → Settings → Notifications
2. Slack/Email 알림 설정
3. 배포 성공/실패 알림 활성화