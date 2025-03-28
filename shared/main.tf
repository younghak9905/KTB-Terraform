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
  source = "../modules/bastion"

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

# GitLab 보안 그룹
resource "aws_security_group" "gitlab_sg" {
  name        = "sg-${var.stage}-${var.servicename}-gitlab"
  description = "Security group for GitLab and GitLab Runner"
  vpc_id      = aws_vpc.my_vpc.id

  # SSH 접속
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [module.bastion.bastion_security_group_id]
    description = "SSH from allowed IPs"
  }

  # HTTP 접속
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.my_vpc.cidr_block]
    description = "HTTP access"
  }

  # HTTPS 접속
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.my_vpc.cidr_block]
    description = "HTTPS access"
  }

  # 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "sg-${var.stage}-${var.servicename}-gitlab"
  }
}

# GitLab 인스턴스 - instance 모듈 사용
module "gitlab_instance" {
  source = "../modules/instance"

  stage             = var.stage
  servicename       = "${var.servicename}-gitlab"
  ami               = "ami-05716d7e60b53d380"  # Amazon Linux 2
  instance_type     = "c5.xlarge"
  subnet_id         = aws_subnet.prv_sub_1a.id
  sg_ec2_ids        = [aws_security_group.gitlab_sg.id]
  ebs_size          = 50
  #kms_key_id        = var.kms_key_id
  ec2-iam-role-profile-name = module.iam_role.ec2-iam-role-profile.name
  
  # user_data 스크립트 파일 로드
  user_data = file("${path.module}/scripts/gitlab.sh")

  # SSH 허용 목록
  ssh_allow_comm_list = []

  # 태그
  tags = {
    Name = "ec2-${var.stage}-${var.servicename}-gitlab"
  }
}

