module "iam_service_role" {
  source      = "../modules/iam/iam-service-role"
  stage       = var.stage
  servicename = var.servicename
  tags        = var.tags  
  
}
