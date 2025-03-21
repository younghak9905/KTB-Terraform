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

resource "aws_security_group" "sg-ec2" {
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
}
/*
module "asg" {
  source                      = "../modules/asg"
  asg_name                    = "my-ecs-asg"
  desired_capacity            = 2
  min_size                    = 1
  max_size                    = 3
  launch_template_id          = module.ecs_ec2.launch_template_id
  launch_template_version     = module.ecs_ec2.launch_template_version
  subnet_ids                  = [var.subnet_service_az1,var.subnet_service_az2]  # 대상 서브넷 ID 리스트
  health_check_type           = "EC2"
  health_check_grace_period   = 300
  instance_name               = var.servicename
  tags                        = { Environment = "stage", Project = "myproject",Type="asg" }
  stage                       = var.stage    
  servicename                 = var.servicename  
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
  internal            = falseS
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

/*
module "ecs_ec2" {
  source      = "../modules/ecs_ec2"
  cluster_name  = "my-ecs-cluster"
  ecs_ami_id    = "ami-05716d7e60b53d380"  # ECS 최적화 AMI ID
  instance_type = "t3.micro"
  key_name      = "my-key"
  user_data     = "#!/bin/bash\nyum update -y"
  instance_name = var.servicename
  tags          = { Environment = "stage", Project = "myproject", Type = "ecs-ec2" }
  vpc_id        = module.vpc.vpc_id
  region        = var.region
  subnet_ids    = [var.subnet_service_az1, var.subnet_service_az2]
  stage         = var.stage
  servicename   = var.servicename 

  # ALB 관련 값 전달 (ALB 모듈의 출력값 사용)
  alb_target_group_arn  = module.alb.target_group_arn
  alb_listener_arn      = module.alb.listener_arn
  
}*/


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
