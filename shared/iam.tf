# IAM 역할 모듈 (EC2 인스턴스 프로파일용)
module "iam_role" {
  source = "../modules/iam/iam-service-role"
  
  stage       = var.stage
  servicename = var.servicename
  tags        = var.tags
}