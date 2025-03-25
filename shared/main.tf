# shared/main.tf

# 공통 태그는 provider 블록의 default_tags에서 정의됨
terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  backend "s3" {
    bucket = "zero9905-terraformstate"
    key    = "shared/terraform/terraform.tfstate"
    region = "us-east-2"
    encrypt = true
    dynamodb_table = "zero9905-terraformstate"
  }
}

# Bastion 서버 (OpenVPN용) 배포
module "bastion" {
  source = "./modules/bastion"

  stage          = var.stage
  servicename    = "${var.servicename}-bastion"
  vpc_id         = aws_vpc.my_vpc.id
  vpc_cidr_block = var.vpc_main_cidr
  subnet_id      = aws_subnet.pub_subnet_1a.id
  ami_id         = var.bastion_ami_id
  instance_type  = var.bastion_instance_type
  key_name       = var.key_name
  root_volume_size = 20
  
  # 선택적으로 SSH 접근을 제한할 CIDR 블록 설정
  ssh_allow_cidr_blocks = var.ssh_allow_cidr_blocks
  admin_cidr_blocks     = var.admin_cidr_blocks
  
  # IAM 인스턴스 프로파일 (SSM과 기타 필요한 권한)
  instance_profile = module.iam_role.ec2-iam-role-profile.name
}
/*

# GitLab 서버 배포
module "gitlab" {
  source = "./modules/gitlab"

  stage             = var.stage
  servicename       = "${var.servicename}-gitlab"
  vpc_id            = aws_vpc.my_vpc.id
  subnet_id         = aws_subnet.prv_sub_1a.id
  availability_zone = var.availability_zone
  ami_id            = var.gitlab_ami_id
  instance_type     = var.gitlab_instance_type
  key_name          = var.key_name
  
  # 데이터 볼륨 크기 설정
  root_volume_size = 30
  data_volume_size = 100
  
  # 보안 그룹 설정
  bastion_sg_id = module.bastion.bastion_security_group_id
  http_sg_list  = [module.bastion.bastion_security_group_id]
  https_sg_list = [module.bastion.bastion_security_group_id]
  
  # IAM 인스턴스 프로파일
  instance_profile = module.iam_role.ec2-iam-role-profile.name
}
*/

