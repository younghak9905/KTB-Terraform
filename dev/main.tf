module "vpc" {
    source = "../modules/vpc"
    
    # VPC 설정
    vpc_ip_range        = "20.0.0.0/16"
    
    # 서브넷 설정 (리스트 활용)
    subnet_public_az1 = "20.0.1.0/24"
    subnet_public_az2 = "20.0.2.0/24"
    subnet_service_az1 = "20.0.3.0/24"
    subnet_service_az2 = "20.0.4.0/24"
    subnet_db_az1      = "20.0.5.0/24"
    subnet_db_az2      = "20.0.6.0/24"

    # 공통 태그 및 환경 변수
    stage               = "dev"
    servicename         = "myservice"
    az                  = ["us-east-2a", "us-east-2c"]
    
    tags = {
      "Project"      = "architecture"
      "Owner"        = "zero"
      "Environment"  = "dev"
    }
}

module "alb" {
  source = "./modules/alb"

  stage       = "dev"
  servicename = "myservice"

  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnets
  instance_ids = module.ec2.instance_ids

  aws_s3_lb_logs_name = "my-log-bucket"
  idle_timeout        = "60"
  port               = "80"

  sg_allow_comm_list = ["0.0.0.0/0"]

  domain     = "example.com"
  hostzone_id = "Z12345678"

  tags = {
    "Project"      = "architecture"
    "Owner"        = "zero"
    "Environment"  = "dev"
  }
}