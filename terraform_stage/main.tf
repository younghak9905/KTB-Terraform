terraform {
 required_version = ">= 1.0.0, < 2.0.0"

  backend "s3" {
    bucket = "zero9905-terraformstate"
    key  = "stage/terraform/terraform.tfstate"
    region = "us-east-2"
    encrypt = true
    dynamodb_table = "zero9905-terraformstate"
  }
}

#
#data "terraform_remote_state" "shared" {
#  backend = "s3"
#  config = {
#    bucket         = "zero9905-terraformstate"
#    key            = "shared/terraform/terraform.tfstate"
#    region         = "us-east-2"
#    dynamodb_table = "zero9905-terraformstate"
#  }
#}

module "vpc" {
  source              = "../modules/vpc"
  stage               = var.stage
  servicename         = var.servicename
  tags                = var.tags

  vpc_ip_range        = var.vpc_ip_range
  az                  = var.az

  subnet_public_az1   = var.subnet_public_az1
  subnet_public_az2   = var.subnet_public_az2
  subnet_service_az1  = var.subnet_service_az1
  subnet_service_az2  = var.subnet_service_az2
  subnet_db_az1       = var.subnet_db_az1
  subnet_db_az2       = var.subnet_db_az2


  ##SecurityGroup
  #sg_allow_comm_list = concat(var.ext_sg_allow_list, ["${module.vpc.nat_ip}/32", var.vpc_ip_range])

  ##TGW
  #create_tgw = var.create_tgw
  #tgw_sharing_accounts = var.tgw_sharing_accounts
#   ext_vpc_route = var.ext_vpc_route
  #security_attachments = var.security_attachments
  #auto_accept_shared_attachments = true
  #security_attachments_propagation = merge(var.security_attachments_propagation, var.security_attachments)
}
/*
module "zero9905-ec2" {
  source              = "../modules/instance"

  stage        = var.stage
  servicename  = "${var.servicename}"
  tags         = var.tags

  ami                       = var.ami
  instance_type             = var.instance_type
  ebs_size                  = var.instance_ebs_size
  user_data                 = <<-EOF
#!/bin/bash 
yum update -y 
yum install -y https://s3.ap-northeast-2.amazonaws.com/amazon-ssm-ap-northeast-2/latest/linux_amd64/amazon-ssm-agent.rpm
EOF
  kms_key_id                = var.ebs_kms_key_id
  ec2-iam-role-profile-name = module.iam-service-role.ec2-iam-role-profile.name
  ssh_allow_comm_list       = [var.subnet_service_az1, var.subnet_service_az2]

  associate_public_ip_address = var.associate_public_ip_address

  subnet_id = module.vpc.public-az1.id
  vpc_id    = module.vpc.vpc_id
  sg_ec2_ids = [aws_security_group.sg-ec2.id]
  depends_on = [module.vpc.sg-ec2-comm, module.iam-service-role.ec2-iam-role-profile]
}*/


# 주석 처리된 remote_state 부분 활성화
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket         = "zero9905-terraformstate"
    key            = "shared/terraform/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "zero9905-terraformstate"
  }
}
/*
# VPC 피어링 추가
module "vpc_peering" {
  source = "../modules/vpc_peering"

  requester_vpc_id         = module.vpc.vpc_id
  accepter_vpc_id          = data.terraform_remote_state.shared.outputs.vpc_id
  requester_cidr_block     = var.vpc_ip_range
  accepter_cidr_block      = data.terraform_remote_state.shared.outputs.vpc_cidr
  requester_route_table_ids = concat(
    [module.vpc.public_route_table_id],
    module.vpc.private_route_table_ids
  )
  accepter_route_table_ids = data.terraform_remote_state.shared.outputs.route_table_ids
  requester_name           = "${var.stage}-${var.servicename}"
  accepter_name            = "shared-infrastructure"
  auto_accept              = true
  
  tags = var.tags

  enable_route_creation = true
}

resource "aws_security_group" "sg-ec2" {
  count = var.create_ec2 ? 1 : 0
  name   = "aws-sg-${var.stage}-${var.servicename}-ec2"
  vpc_id = module.vpc.vpc_id
 
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    description = ""
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    description = ""
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    description = ""
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(tomap({
         Name = "aws-sg-${var.stage}-${var.servicename}-ec2"}), 
        var.tags)

        lifecycle {
    create_before_destroy = true
    ignore_changes = [ingress]
  }
}
*/
module "alb" {
  source = "../modules/alb"

  # 공통 변수
  stage       = var.stage
  servicename = var.servicename
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = [module.vpc.public_az1, module.vpc.public_az2]
  tags        = var.tags

  # ALB 설정
  internal            = false
  aws_s3_lb_logs_name = var.aws_s3_lb_logs_name
  idle_timeout        = 60
  # domain, hostzone_id 등 추가 가능

  # Target Group 설정
  target_type           = "instance"
  port                  = 80
  hc_path               = "/"
  hc_healthy_threshold  = 5
  hc_unhealthy_threshold = 2

  # 보안 그룹 설정
  sg_allow_comm_list = ["0.0.0.0/0"]  # 필요 시 수정

}

# terraform_stage/main.tf에 추가
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/terraform-zero9905"
  retention_in_days = 7

  tags = var.tags
}


module "ecs" {
  source = "../modules/ecs"
  vpc_id = module.vpc.vpc_id
  cluster_name                = "terraform-zero9905-ecs-cluster"
  ami_id    = "ami-059601b8419c53014"  # ECS 최적화 AMI ID
  instance_type = "t3.micro"
  subnet_ids    = [module.vpc.service_az1, module.vpc.service_az2]
  associate_public_ip_address = true
  desired_capacity            = 1
  min_size                    = 1
  max_size                    = 3
  instance_name               = "terrafom-zero9905-ecs-instance"
  sg_alb_id = module.alb.sg_alb_id
  key_name = var.key_name
  # Bastion 보안 그룹 ID 추가 (shared 디렉토리에서 Bastion 서버를 배포한 후 출력값을 사용)
  //shared_vpc_cidr = data.terraform_remote_state.shared.outputs.vpc_cidr

  # ECS Task 변수
  task_family                 = "zero-task-family"
  task_network_mode           = "bridge"
  container_definitions       = file("./container_definitions.json")
  task_cpu                    = "256"
  task_memory                 = "512"
  service_name                = "my-ecs-service"
  service_desired_count       = 1

  # ALB 연동 설정
  alb_target_group_arn  = module.alb.target_group_arn
  container_name        = "nginx"  # container_definitions.json의 컨테이너 이름과 일치해야 함
  container_port        = 80      # container_definitions.json의 포트와 일치해야 함

  tags = {
    Environment = "stage"
    Project     = "ecs-project"
  }
  depends_on = [aws_cloudwatch_log_group.ecs_logs]
}


#RDS
# module "rds" {
#   #default engin aurora-mysql8.0
#   source       = "../modules/aurora"
#   stage        = var.stage
#   servicename  = var.servicename
  
#   tags = var.tags
#   dbname = var.rds_dbname
 
# #  sg_allow_ingress_list_aurora    = var.sg_allow_ingress_list_aurora
# #  sg_allow_ingress_sg_list_aurora = concat([module.vpc.sg-ec2-comm.id, module.eks.eks_node_sg_id], var.sg_allow_list_aurora_sg_add)
#   sg_allow_ingress_list_aurora = var.sg_allow_ingress_list_aurora
#   network_vpc_id                  = module.vpc.network-vpc.id
#   subnet_ids = [module.vpc.db-az1.id, module.vpc.db-az2.id]
#   az           = var.az

#   rds_instance_count = var.rds_instance_count

#   kms_key_id = var.rds_kms_arn
#   depends_on = [module.vpc]
# }
